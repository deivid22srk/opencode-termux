import { Schema } from "effect"
import { HttpApi, HttpApiEndpoint, HttpApiGroup, OpenApi } from "effect/unstable/httpapi"
import { Authorization } from "../middleware/authorization"
import { InstanceContextMiddleware } from "../middleware/instance-context"
import {
  WorkspaceRoutingMiddleware,
  WorkspaceRoutingQueryFields,
} from "../middleware/workspace-routing"
import { described } from "./metadata"

/**
 * Direct tool execution API (fork addition - see CHANGES.md).
 *
 * Lets a trusted local client (e.g. the VibeBridge browser extension) run a
 * single OpenCode tool (bash, read, write, edit, glob, grep...) directly,
 * WITHOUT going through a session/agent prompt. Intended for agentic UIs that
 * implement their own loop. Opt-in via `OPENCODE_TOOL_API=1` so a plain
 * `opencode serve` keeps its interactive permission prompts intact: tools run
 * here with permissions auto-approved.
 */

export class ToolApiDisabled extends Schema.TaggedErrorClass<ToolApiDisabled>()(
  "ToolApiDisabled",
  { message: Schema.String },
  { httpApiStatus: 403 },
) {}

export class ToolNotFound extends Schema.TaggedErrorClass<ToolNotFound>()(
  "ToolNotFound",
  { message: Schema.String },
  { httpApiStatus: 404 },
) {}

export class ToolExecutionFailed extends Schema.TaggedErrorClass<ToolExecutionFailed>()(
  "ToolExecutionFailed",
  { message: Schema.String },
  { httpApiStatus: 400 },
) {}

export const ToolListResponse = Schema.Struct({
  tools: Schema.Array(
    Schema.Struct({
      id: Schema.String,
      description: Schema.optional(Schema.String),
    }),
  ),
}).annotate({ identifier: "ToolList" })

export const ToolExecResponse = Schema.Struct({
  title: Schema.String,
  output: Schema.String,
  metadata: Schema.optional(Schema.Unknown),
}).annotate({ identifier: "ToolExecResult" })

export const ToolExecPayload = Schema.Struct({
  arguments: Schema.optional(Schema.Record(Schema.String, Schema.Unknown)),
})

export const ToolQuery = Schema.Struct({
  ...WorkspaceRoutingQueryFields,
})

export const ToolPaths = {
  list: "/tool",
  exec: "/tool/:name",
} as const

export const ToolApi = HttpApi.make("tool").add(
  HttpApiGroup.make("tool")
    .add(
      HttpApiEndpoint.get("list", ToolPaths.list, {
        query: ToolQuery,
        success: described(ToolListResponse, "Available tools"),
        error: ToolApiDisabled,
      }).annotateMerge(
        OpenApi.annotations({
          identifier: "tool.list",
          summary: "List tools",
          description: "List the tools available for direct execution.",
        }),
      ),
      HttpApiEndpoint.post("exec", ToolPaths.exec, {
        params: { name: Schema.String },
        payload: ToolExecPayload,
        success: described(ToolExecResponse, "Tool execution result"),
        error: Schema.Union([ToolApiDisabled, ToolNotFound, ToolExecutionFailed]),
      }).annotateMerge(
        OpenApi.annotations({
          identifier: "tool.exec",
          summary: "Execute a tool",
          description:
            "Execute a single tool directly (permissions are auto-approved; requires OPENCODE_TOOL_API=1).",
        }),
      ),
    )
    .annotateMerge(
      OpenApi.annotations({
        title: "tool",
        description: "Direct tool execution API (fork addition, opt-in via OPENCODE_TOOL_API=1).",
      }),
    )
    .middleware(InstanceContextMiddleware)
    .middleware(WorkspaceRoutingMiddleware)
    .middleware(Authorization),
)
