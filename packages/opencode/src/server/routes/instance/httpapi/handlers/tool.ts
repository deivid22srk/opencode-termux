import { Effect, Layer } from "effect"
import { HttpApiBuilder } from "effect/unstable/httpapi"
import { Service as ToolRegistryService } from "@/tool/registry"
import type * as Tool from "@/tool/tool"
import { InstanceHttpApi } from "../api"
import {
  ToolApiDisabled,
  ToolExecutionFailed,
  ToolNotFound,
} from "../groups/tool"

/**
 * Handlers for the direct tool execution API (fork addition - see CHANGES.md).
 *
 * Executes one tool through the normal ToolRegistry pipeline (argument
 * validation, output truncation, spans) with a synthetic tool context:
 * - permissions are AUTO-APPROVED (`ask` resolves immediately) - the endpoint
 *   is opt-in via OPENCODE_TOOL_API=1 exactly because of this;
 * - no session/message is created; the tools this API is meant for (bash,
 *   read, write, edit, glob, grep) do not touch session history (bash tags
 *   its process record with the synthetic session id, which is harmless).
 */
export const toolHandlers = HttpApiBuilder.group(InstanceHttpApi, "tool", (handlers) =>
  Effect.gen(function* () {
    const registry = yield* ToolRegistryService

    const gate = Effect.fn("ToolHttpApi.gate")(function* () {
      if (process.env.OPENCODE_TOOL_API !== "1") {
        return yield* Effect.fail(
          new ToolApiDisabled({
            message:
              "The direct tool API is disabled. Start the server with OPENCODE_TOOL_API=1 to enable it (e.g. `OPENCODE_TOOL_API=1 opencode serve --port 4096`).",
          }),
        )
      }
    })

    const list = Effect.fn("ToolHttpApi.list")(function* () {
      yield* gate()
      const all = yield* registry.all()
      return {
        tools: all.map((t) => ({ id: t.id, description: t.description || undefined })),
      }
    })

    const exec = Effect.fn("ToolHttpApi.exec")(function* (ctx: {
      params: { name: string }
      payload?: { arguments?: Record<string, unknown> }
    }) {
      yield* gate()
      const all = yield* registry.all()
      const def = all.find((t) => t.id === ctx.params.name)
      if (!def) {
        return yield* Effect.fail(
          new ToolNotFound({
            message: `Unknown tool "${ctx.params.name}". GET /tool lists the available tools.`,
          }),
        )
      }
      const input = ctx.payload?.arguments ?? {}
      // The registry's execute wrapper decodes arguments (InvalidArgumentsError)
      // and surfaces tool errors ("File not found", command failures, ...) as
      // defects (Effect.orDie), so a single catchDefect gives the client a
      // clean, model-readable message for both cases.
      const result = yield* def.execute(input as never, {
        sessionID: `ses_toolapi-${Date.now().toString(36)}` as Tool.Context["sessionID"],
        messageID: `msg_toolapi-${Date.now().toString(36)}` as Tool.Context["messageID"],
        agent: "build",
        abort: new AbortController().signal,
        messages: [],
        metadata: () => Effect.void,
        ask: () => Effect.void,
      }).pipe(
        Effect.catchDefect((e) =>
          Effect.fail(
            new ToolExecutionFailed({ message: e instanceof Error ? e.message : String(e) }),
          ),
        ),
      )
      return { title: result.title, output: result.output, metadata: result.metadata }
    })

    return handlers.handle("list", list).handle("exec", exec)
  }),
)
