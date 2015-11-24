ccc = 8

sync = ()->
  throw new Error 'Sync'
  return 123

someAsyncFunc = (cb)->
  throw new Error 'Async'
  return

bbb = sync()

someOtherAsyncFunc ()->
  throw new Error 'Async'
  return

