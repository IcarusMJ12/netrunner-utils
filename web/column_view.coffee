class SortedObject
    constructor: (obj, @sorting_function) ->
        @items = if obj? then obj else {}
        @keys = $.keys(@items)
        @keys.sort(@sorting_function)
    
    values: ->
        return (@items[key] for key in @keys)

    insert: (key, value) ->
        @keys.splice($.sortedIndex(@keys, key), 0, key)
        @items[key] = value
    
    remove: (key) ->
        delete @items[key]
        @keys.splice($.indexOf(@keys, key, true), 1)

class SortedObjectTree
    constructor: (obj, @sorting_function) ->
        @root = @_makeTreeR(JSON.parse(JSON.stringify(obj))) #retarded deepcopy
    
    _makeTreeR: (obj) ->
        for key, value of obj
            if value instanceof Object
                obj[key] = @_makeTreeR(value)
        return new SortedObject(obj, @sorting_function)

    insert: (keys, value, node=@root) ->
        if not keys instanceof Array
            keys = [keys]
        if keys.length is 1
            node.insert(keys[0], value)
            return
        node = node.items[node.keys[keys[0]]]
        @insert(keys[1..], value, node)
    
    remove: (keys, node=@root, recursive=False) ->
        if not keys instanceof Array
            keys = [keys]
        if keys.length is 0
            return
        if keys.length is 1
            node.remove(keys[0])
            return
        next_node = node.items[node.keys[keys[0]]]
        @remove(keys[1..], next_node)
        if recursive and node.keys.length == 0
            node.remove(keys[0])
    
    get: (keys, node=@root) ->
        console.log('keys: ' + keys + ' node: ' + node)
        if keys.length is 0
            if node instanceof SortedObject
                return node.keys
            else
                return node
        return @get(keys[1..], node.items[keys[0]])
    
class @ColumnView
    constructor: (@container) ->
        @current_path = []
        @columns = $.create("<div>")
        @columns.addClass('columnview_columns')
        $(@container).append(@columns)
        @real_columns = []
    
    _pushColumn: (path) ->
        col = $.create('<div>')
        col.addClass('columnview_column')
        col[0].style.display = 'none'
        values = @data.get(path)
        console.log(values)
        if values instanceof Array
            for value in values
                entry = $.create('<div>')
                entry.addClass('columnview_entry')
                entry.addClass('clickable')
                entry[0].innerHTML = value
                keys = $.clone(path)
                keys.push(value)
                entry[0].onclick = do (col, entry, keys) =>
                    () => @goto(col, entry, keys)
                col.append(entry[0])
        else
            entry = $.create('<div>')
            entry.addClass('columnview_entry')
            entry[0].innerHTML = values
            col.append(entry[0])
        @columns.append(col[0])
        @real_columns.push(col)
        col[0].style.display = 'inline-block'
    
    _popColumn: () ->
        last = @real_columns.pop()
        $(last).remove()

    _setColumnsWidth: () ->
        @columns[0].style.width = Math.max($.reduce(@real_columns, `function (memo, col) { return memo + col[0].style.offsetWidth }`, 0), @container.offsetWidth) + 'px'

    fill: (data) ->
        @data = new SortedObjectTree(data)
        @columns.empty()
        @real_columns = []
        @_pushColumn([])
        @current_path = []
        @_setColumnsWidth()
    
    goto: (col, entry, keys) ->
        console.log(entry)
        col.children().each( (child, index) => child.className = 'columnview_entry clickable' )
        entry.addClass('columnview_selected')
        end = Math.min(keys.length, @current_path.length)
        common = 0
        while common < end
            if keys[common] isnt @current_path[common]
                break
            common += 1
        console.log(keys + ' ' + @current_path + ' ' + common)
        popped = false
        for key in @current_path[common..@current_path.length-1]
            console.log("-column")
            @_popColumn()
        if keys.length > common
            for i in [common..keys.length-1]
                console.log("+column " + keys[..i])
                @_pushColumn(keys[..i])
        @real_columns[@real_columns.length-1].children().each( (child, index) => child.className = 'columnview_entry clickable' )
        @_setColumnsWidth()
        @current_path = keys
