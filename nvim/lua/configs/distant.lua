-- distant.nvim configuration
-- Remote development plugin for editing files on Raspberry Pi or other servers

return {
  -- Client settings (local distant binary)
  client = {
    bin = '/Users/lukasz/.local/bin/distant',
  },

  -- Manager settings
  manager = {
    daemon = false,
  },

  -- Network settings
  network = {
    timeout = {
      max = 60000,
    },
  },

  -- Server configurations
  servers = {
    -- Default settings for all servers
    ['*'] = {
      connect = {
        default = {
          scheme = 'ssh',
        },
      },
      launch = {
        default = {
          bin = '/home/ukibbb/.local/bin/distant',
        },
      },
      lsp = {
        ['*'] = {},
      },
    },

    -- Raspberry Pi configuration
    ['raspberry'] = {
      connect = {
        default = {
          scheme = 'ssh',
          host = '192.168.101.7',
          username = 'ukibbb',
        },
      },
      launch = {
        default = {
          bin = '/home/ukibbb/.local/bin/distant',
          host = '192.168.101.7',
          username = 'ukibbb',
        },
      },
    },
  },
}
