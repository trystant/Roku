' The home screen for this app is a poster list of products
' where the filter row contains product types.
Function InitHome(store as Object) As Object
    this = {
        screen           : CreateObject("roPosterScreen")
        store            : store
        shown            : false
        done             : false
        listNames        : []
        listName         : ""
        listIndex        : 0
        itemIndex        : 0
        Handle           : home_handle_message
        Update           : home_update
        Move             : home_move
    }
    this.screen.SetListStyle("flat-episodic")
    this.screen.SetMessagePort(store.cart.GetMessagePort())
    return this
End Function

' Display the products and wait for events from the screen and store.
' The screen will show retreiving while we wait for the first product list.
Function home_handle_message(msg as Object) As Boolean
    if msg.isListFocused() then
        m.update(msg.GetIndex())
        print "Home: list focused | current category = "; msg.GetIndex()
    else if msg.isListItemFocused() then
        print"Home: list item focused | current item = "; msg.GetIndex()
    else if msg.isListItemSelected() then
        print "Home: list item selected | current item = "; msg.GetIndex() 
        m.itemIndex = msg.GetIndex()
        return true
    else if msg.isScreenClosed() then
        m.done = true ' close/exit
        return true
    end if
    return false
End Function

' Refresh the screen with newly received products or product types.
function home_update(listIndex=-1 as Integer)
    store = m.store
    screen = m.screen
    typesChanged = store.typesChanged
    typeName = invalid
    if typesChanged
        store.typesChanged = false
        types = store.getProductTypes()
        screen.SetListNames(types)
        tc = types.count()
        for listIndex = 0 to tc
            if types[listIndex]=m.listName then exit for
        end for
        m.listNames = types
        if tc>0
            listIndex = listIndex mod tc
            screen.SetFocusedList(listIndex)
        end if
        if not m.shown
            screen.Show()
            m.shown = true
        end if
    end if
    if listIndex<0 then listIndex = m.listIndex
    if typesChanged or store.productsChanged or listIndex<>m.listIndex
        m.listIndex = listIndex
        m.listName = m.listNames[listIndex]
        store.productsChanged = false
        products = store.getProductsByIndex(listIndex)
        if products=invalid then products = []
        screen.SetContentList(products)
        if products.count()=0
            screen.ShowMessage("No items")
        else
            m.move(0,products)
        end if
    end if
end function

' Update the item focus.
function home_move(itemDelta=0 as Integer, products=invalid as Dynamic) as Dynamic
    if products=invalid then products = m.store.getProductsByIndex(m.listIndex)
    if products<>invalid
        pc = products.count()
        if pc>0
            m.itemIndex = (m.itemIndex + itemDelta + pc) mod pc
            m.screen.SetFocusedListItem(m.itemIndex)
            return products[m.itemIndex]
        end if
    end if
    return invalid
end function

