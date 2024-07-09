local M = {}

function M.setup()

  if KmanTopicPlugin then return end
  KmanTopicPlugin = M

  M._path_sep = vim.fn.has("win32") == 1 and "\\" or "/"

  vim.api.nvim_create_user_command(
    "Kman", KmanTopicPlugin.kman_cmd, {nargs = "*"}
  )

end

function M.kman_cmd(cmd_arg)
  -- processes 'Kman' command.
  --
  -- shows specified topic, or err message if topic was not found

  local topic_name = cmd_arg.fargs[1] or "vim"

  local topic_file = M._find_topic(topic_name)

  local lines = {}
  if not topic_file then
    lines[1] = topic_name .. " not found"
  else
    for line in io.lines(topic_file) do
      if #lines ~= 0 or string.sub(line, 1, 3) ~= "-- " then
        lines[#lines + 1] = line
      end
    end
  end

  M._show_popup(lines)

end

-- function M._get_topics_list()
--   local xx = vim.fn.readdir("/home/lesnik/.kman/topics")
--   for i, line in ipairs(xx) do
--     if line:match(".topic$") then
--       lines[#lines + 1] = line
--     end
--   end
-- end

function M._find_topic(topic_name)
  -- topic name -> path to the file, which contains the topic.

  topic_name = topic_name or "vim"

  local topics_dirs = M._get_topics_dirs()

  for i, topics_dir in ipairs(topics_dirs) do
    local candidate = topics_dir .. M._path_sep .. topic_name .. ".topic"
    if M._file_exists(candidate) then
      return candidate
    end
  end
  return nil
end

function M._get_topics_dirs()
  -- get list of dirs, which contain topic files.
  -- Usually there is only one such dir: ~/.kman/topics
  -- (additional directories may be specified in kman config - not implemented yet)
  local user_home = vim.fn.expand("$HOME")

  local topics_dirs = {}
  topics_dirs[#topics_dirs+1] = (user_home .. M._path_sep ..
    ".kman" .. M._path_sep .. "topics")

  return topics_dirs
end


function M._file_exists(file_path)
  local f = io.open(file_path, "r")
  if f ~= nil then
    io.close(f)
    return true
  end
  return false
end


function M._show_popup(lines)
  -- create popup to show given lines

  local width = 50
  for i, line in ipairs(lines) do
    width = math.max(string.len(line), width)
  end
  local height = #lines

  local current_ui = vim.api.nvim_list_uis()[1]

  width = math.min(width, math.max(50, current_ui.width - 10))
  height = math.min(height, math.max(current_ui.height - 4, 5))

  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = (current_ui.width - width) / 2,
    row = (current_ui.height - height) / 2,
    anchor = "NW",
    style = "minimal",
  }

  local buf = vim.api.nvim_create_buf(0, 1)
  vim.api.nvim_buf_set_lines(buf, 0, -1, 0, lines)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'kmantopic')

  for i, esc_key in ipairs({'<ESC>', '<CR>', 'q'}) do
    vim.api.nvim_buf_set_keymap(
      buf, 'n', esc_key, ':close<CR>', {
        silent=true,
        nowait=true,
        noremap=true,
      })
  end

  local win = vim.api.nvim_open_win(buf, 1, opts)

end


return M
