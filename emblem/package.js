Package.describe({
  summary: "a concise and beautiful alternative to Handlebars.js"
});

Npm.depends({
  handlebars: '1.3.0',
  emblem: '0.3.11'
});

Package._transitional_registerBuildPlugin({
  name: "compileEmblem",
  use: ['handlebars', 'coffeescript', 'underscore'],
  sources: [
    'plugin/emblem-scanner.coffee',
    'plugin/handlebars-extension.js'
  ],
  npmDependencies:{"handlebars":"1.3.0","emblem":"0.3.11"}
});

Package.on_use(function(api) {
  api.use(['handlebars', 'coffeescript'], 'server');
  api.export('EmblemScanner', 'server', {testOnly: true});
  api.add_files('plugin/emblem-scanner.coffee', 'server');
  api.add_files('plugin/handlebars-extension.js', 'server');
});

Package.on_test(function (api) {
  api.use(['emblem', 'handlebars', 'tinytest', 'coffeescript'], 'server');
  api.add_files([
    'tests/scan_tests.coffee',
    'tests/scan_section_tests.coffee',
    'tests/emblem_tests.coffee',
  ], 'server');
});
