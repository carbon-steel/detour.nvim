rockspec_format = '3.0'
package = 'detour.nvim'
version = 'scm-1'

test_dependencies = {
  'lua >= 5.1',
}

source = {
  url = 'git://github.com/carbon-steel/' .. package,
}

build = {
  type = 'builtin',
}
