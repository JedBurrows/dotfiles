/**
 * Status bar extension showing model, current context (cwd), and git branch.
 *
 * Auto-enables on every session start. Uses ctx.ui.setFooter() for a persistent
 * custom footer that reacts to git branch changes.
 */

import { basename } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		ctx.ui.setFooter((tui, theme, footerData) => {
			const unsub = footerData.onBranchChange(() => tui.requestRender());

			return {
				dispose: unsub,
				invalidate() {},
				render(width: number): string[] {
					const model = ctx.model?.id ?? "no-model";
					const branch = footerData.getGitBranch();
					const cwd = process.cwd();
					const context = basename(cwd);

					// Styled segments
					const modelStr = theme.fg("accent", model);
					const contextStr = theme.fg("muted", context);
					const branchStr = branch
						? theme.fg("dim", "git:") + theme.fg("success", branch)
						: theme.fg("dim", "no-git");

					// Build left and right parts
					const left = `${modelStr}  ${contextStr}`;
					const right = branchStr;

					const leftWidth = visibleWidth(left);
					const rightWidth = visibleWidth(right);
					const padWidth = Math.max(1, width - leftWidth - rightWidth);
					const pad = " ".repeat(padWidth);

					return [truncateToWidth(left + pad + right, width)];
				},
			};
		});
	});
}
