Tinytest.add "emblem scanner - scanSection", (test) ->
  checkScanSection = (section, expected...) ->
    s = new EmblemScanner
    called = null
    s._handleTag = (args...) -> called = args
    s._scanSection(section)
    test.equal(called, expected)

  checkScanSection(
    """
    template name="foo"
      .hi Hello {{full_name}}
      p Bye
    """,
    'template', {name: 'foo'},
    """
    > .hi Hello {{full_name}}
      p Bye
    """.replace('>', ' ')
  )
