Tinytest.add "emblem scanner - scan", (test) ->
  checkOverallParsing = (text, sections...) ->
    s = new EmblemScanner
    called = []
    s._scanSection = (section) -> called.push(section)
    s.scan(text)
    test.equal(called, sections)

  checkOverallParsing(
    """
    / Complete example
    head
      title Ho
    / Body starts here
    body
      p Hello
      p World
      / Body ends here
    template name="foo"
      .hi Hello {{full_name}}
    template name="bar"
      .here World
    """,
    """
    head
      title Ho

    """,
    """
    body
      p Hello
      p World
      / Body ends here
    """,
    """
    template name="foo"
      .hi Hello {{full_name}}
    """,
    """
    template name="bar"
      .here World
    """
    )
