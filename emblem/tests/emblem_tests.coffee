Tinytest.add "emblem scanner - simple", (test) ->
  r = EmblemScanner.scan(
    """
    body
      .hi Hello {{full_name}}
      p World
    """, "test source"
  )
  test.matches(r.js, /"full_name"/)
  test.matches(r.js, /"<div class=."hi.">Hello/)

Tinytest.add "emblem scanner - with head", (test) ->
  r = EmblemScanner.scan(
    """
    / Complete example
    head
      title Ho
    / Body starts here
    body
      | The body
      / Body ends here
    """, "test source"
  )
  test.equal(r.head, "<title>Ho</title>")
  test.matches(r.js, /The body/)

Tinytest.add "emblem scanner - template", (test) ->
  r = EmblemScanner.scan(
    """
    / Complete example
    head
      title Ho
    / Body starts here
    body
      > foo
      p World
      / Body ends here
    template name="foo"
      .hi Hello {{full_name}}
    """, "test source"
  )
  test.matches(r.js, /<p>World<.p>"/)
  test.matches(r.js, /Template.__define__."foo"/)
