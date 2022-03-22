local worktree = require("git-worktree")
worktree.setup({
    change_directory_command = "cd", -- default: "cd",

--  this command will only be run when the current file is not found in the new worktree.
--  This option defaults to e . which opens the root directory of the new worktree.
    update_on_change = true, -- default: true,
    update_on_change_command = "e .", -- default: "e .",
--autopush: When creating a new worktree,
--it will push the branch to the upstream then perform a git rebase
    clearjumps_on_change =  true, -- default: true,
    autopush = false, -- default: false,
})


worktree.on_tree_change(function(op, metadata)
 if op == worktree.Operations.Switch then
    print("Switched from " .. metadata.prev_path .. " to " .. metadata.path)
  end
end)

require("telescope").load_extension("git_worktree")

-- :lua require('telescope').extensions.git_worktree.create_git_worktree()
--:lua require('telescope').extensions.git_worktree.git_worktrees()
-- <Enter> - switches to that worktree
-- <c-d> - deletes that worktree
-- <c-f> - toggles forcing of the next deletion
