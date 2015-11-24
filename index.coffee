#isEmptyCode = (node, astApi) ->
#  nodeName = astApi.getNodeName node
#  nodeName is 'Code' and node.body.isEmpty()

getNodeType = (node)->
  return node.constructor.name

isCallbackVar = (var_name)->

  regex = ///
    (^(cb|cbb|callback|cb2)$)   # var name exact matches
    | (^cb_)                    # var name that start with "cb_"
    | (_cb$)                    # var name that end with "_cb"
    | res                       # var name is part of express
  ///i

  return regex.test var_name



module.exports = class ThrowInsideAsync

  blocks: []

  rule:
    name: 'throw_inside_async'
    level: 'error'
    message: 'throw inside of an async. callback(err) instead'
    description: '''
      Detects a throw inside of an async function.
      Throws should only be in sync functions.
      A func is considered async if it contains a parameter that looks like a callback's variable name
    '''

  lintAST: (node, astApi) ->
    @astApi = astApi
    @lintNode node, astApi
    return

  lintCall: (node)->
    node.eachChild (child)=>
      switch getNodeType(child)
        when 'Code'
          error_location_data = @hasThrow node
          if error_location_data
            err = @astApi.createError
              lineNumber: error_location_data.first_line + 1
              columnNumber: error_location_data.first_column + 1
            @errors.push err
      return
    return

  lintCode: (node)->

#    console.log 'lint code', getNodeType(node)

    is_async = false
    node.eachChild (child)=>
#      console.log 'child', getNodeType(child)
      switch getNodeType(child)
        when 'Param'
#          console.log 'param', JSON.stringify(child)
          if isCallbackVar child.name.value
            is_async = true
      return

    if is_async
#      console.log 'is async'
      error_location_data = @hasThrow node
      if error_location_data
        err = @astApi.createError
          lineNumber: error_location_data.first_line + 1
          columnNumber: error_location_data.first_column + 1
        @errors.push err

    return

  hasThrow: (node)->
    if getNodeType(node) is 'Throw'
      return node.locationData


    throw_location_data = null
    node.eachChild (child)=>
      throw_location_data = @hasThrow child
      if throw_location_data
        return false
      return
    return throw_location_data

  lintNode: (node) ->

    node_name = getNodeType node

    # starting a code block
    switch node_name
      when 'Code'
        @lintCode node
      when 'Call'
        @lintCall node

    node.eachChild (child) => @lintNode child
    return