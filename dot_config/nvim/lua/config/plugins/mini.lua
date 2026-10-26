return {
  {
    'echasnovski/mini.nvim',
    'echasnovski/mini.icons',
    config = function()
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = true }
    end
  },
}
