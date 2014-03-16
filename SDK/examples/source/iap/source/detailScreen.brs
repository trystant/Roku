' The detail screen for this app is a springboard display
' of the various metadata fields for a selected product
' with menu items that allow adding/removing from the cart
' and purchase of the whole cart contents.

function InitDetail(parent as Object) as Object
    this = {
        parent           : parent
        store            : parent.store
        listIndex        : 0
        itemIndex        : -1
        cartOps          : ["back", "purchase", "add", "subtract"]
        upgradeOps       : ["back", "upgrade"]
        opType           : ""
        Handle           : detail_handle_message
        Update           : detail_update
        Move             : detail_move
    }
    return this
end function

' create or refresh the detail screen for a product
function detail_update(product=invalid as Dynamic)
    screen = m.screen
    if screen=invalid
        screen = CreateObject("roSpringboardScreen")
        screen.SetMessagePort(m.store.cart.GetMessagePort())
        screen.SetDescriptionStyle("generic")
        screen.setStaticRatingEnabled(false)
        screen.SetPosterStyle("rounded-square-generic")
        screen.show()
        m.screen = screen
        m.opType = ""
    end if
    if product=invalid then product = m.product
    if product<>invalid
        m.product = product
        product.title = product.name
        price = ""
        if nonEmptyStr(product.cost) then price = product.cost else if nonEmptyStr(product.amount) then price = product.amount
        if nonEmptyStr(product.paymentSchedule) then price = price + " " + product.paymentSchedule
        product.Headers = [price]
        product.LabelAttrs = ["bought","cart","type"]
        bought = "" : if product.purchasesqty<>invalid then bought = Stri(product.purchasesqty).Trim()
        cart = "" : if product.cartqty<>invalid then cart = Stri(product.cartqty).Trim()
        product.LabelVals = [bought,cart,product.productType]
        if nonEmptyStr(product.purchaseDate) then product.Footers = ["last purchase", product.purchaseDate]
        m.screen.AllowUpdates(false)
        screen.SetContent(product)
        if product.code=invalid or product.code="" then opType = "upgradeOps" else opType = "cartOps"
        if m.opType<>opType
            m.opType = opType
            btnTexts = m[opType]
            m.screen.ClearButtons()
            for btnIndx = 0 to btnTexts.count()-1
                m.screen.addButton(btnIndx, btnTexts[btnIndx])
            end for
        end if
        m.screen.AllowUpdates(true)
    else
        screen = invalid
    end if
end function

' show a different product according to parent order
function detail_move(delta as Integer)
    m.update(m.parent.move(delta))
end function 

' process detail screen UI actions
function detail_handle_message(msg as Object) as Boolean
    op = "back"
    idx = msg.GetIndex()
    if msg.isButtonPressed()
        op = m[m.opType][idx]
    else if msg.isRemoteKeyPressed()
        if idx=4 then op = "left" else if idx=5 then op = "right"
    end if 
    print "Detail: cart op "; op
    if op="back"
        m.screen = invalid
    else if op="add"
        m.store.DeltaCart(m.product, 1)
        m.update()
    else if op="subtract"
        m.store.DeltaCart(m.product, -1)
        m.update()
    else if op="left"
        m.move(-1)
    else if op="right"
        m.move(1)
    else
        m.store.action(op)
        m.screen = invalid
    end if
    return m.screen=invalid
end function

