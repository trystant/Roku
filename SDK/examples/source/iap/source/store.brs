function InitStore(port as Object) as Object
    this = {
        cart                : CreateObject("roChannelStore")
        products            : {}
        allProducts         : {}
        queries             : {catalog : true, storecatalog : true, upgrades : true, purchases : true}
        dirty               : {}
        typesChanged        : true
        productsChanged     : true
        actionInProgress    : ""
        Action              : store_action
        Handle              : store_handle_message
        AddProducts         : store_add_products
        UpdateProduct       : store_update_product
        GetProducts         : store_get_products
        GetProductTypes     : store_get_product_types
        GetProductsByIndex  : store_get_products_by_index
        GetProductByIndexes : store_get_product_by_indexes
        DeltaCart           : store_delta_cart
        ClearCart           : store_clear_cart
    }
    this.dirty.append(this.queries)
    this.cart.setMessagePort(port)
    return this
end function

' Submit queries to refresh categories
function store_action(action="" as String)
    if m.actionInProgress<>"" then return success ' one at a time
    m.dirty.Reset()
    if action="" and m.dirty.IsNext() then action = m.dirty.Next()
    m.actionInProgress = action
    print "Store: action "; action
    if      action="catalog"
        m.cart.GetCatalog()
    else if action="storecatalog"
        m.cart.GetStoreCatalog()
    else if action="upgrades"
        m.cart.GetUpgrade()
    else if action="purchases"
        m.cart.GetPurchases()
    else if action="purchase"
        m.AddProducts("purchase",[])
        if m.cart.DoOrder() then m.dirty.purchases = true
        m.ClearCart()
    else if action="upgrade"
        m.upgradeID = m.cart.DoUpgrade()
    end if
    m.dirty.delete(action)
end function

' Process results from server
function store_handle_message(msg as Object) as String
    status = ""
    if msg.isRequestSucceeded()
        m.AddProducts(m.actionInProgress, msg.GetResponse())
        print "Store: successful "; m.actionInProgress
    else if msg.isRequestInterrupted()
        status = m.actionInProgress + " 'cancelled by user'"
        print "Store: interrupted "; status
    else
        status = m.actionInProgress + " '" + msg.GetStatusMessage() + "'"
        print "Store: failed "; status
    end if
    m.actionInProgress = "" ' action completed
    return status
end function

' Reload a category from new results
function store_add_products(productType as String, products as Object)
    m.productsChanged = true
    typedProducts = m.GetProducts(productType)
    typedProducts.clear()
    for each product in products
        updatedProduct = m.updateProduct(product)
        if updatedProduct<>invalid
            updatedProduct[productType+"qty"] = product.qty
            typedProducts.push(updatedProduct)
        end if
    end for
end function

' Update all categories' info for this product
function store_update_product(product as Object) as Dynamic
    updatedProduct = invalid
    if product.code<>invalid and product.code<>""
        updatedProduct = m.allProducts[product.code]
        if updatedProduct=invalid
            ' filter out tax and shipping line items on completed order
            if product.name<>invalid and product.name<>""
                m.allProducts[product.code] = product
                updatedProduct = product
            end if
        else
            updatedProduct.append(product)
        end if
    end if
    return updatedProduct
end function

' Get a list of the product categories
function store_get_product_types() as Object
    productTypes = []
    for each productType in m.products
        productTypes.push(productType)
    end for
    return productTypes
end function

' Get the product list for a named category
function store_get_products(productType as String) as Object
    typedProducts = m.products[productType]
    if typedProducts=invalid
        typedProducts = []
        m.products[productType] = typedProducts
        m.typesChanged = true
    end if
    return typedProducts
end function

' Get the product list by its sequential index
function store_get_products_by_index(typeIndex as Integer) as Dynamic
    for each productType in m.products
        if typeIndex=0 then return m.products[productType]
        typeIndex = typeIndex -1
    end for
    print "Store: no such product type #"; typeIndex
    return invalid
end function

' Get a specific product by category and item index
function store_get_product_by_indexes(typeIndex as Integer, productIndex as Integer) as Dynamic
    products = m.GetProductsByIndex(typeIndex)
    if products<>invalid then product = products[productIndex] else product = invalid
    if product=invalid then print "Store: no such product ("; typeIndex; ","; productIndex; ")"
    return product
end function

' Change the cart quantity for a product
function store_delta_cart(product as Object, delta as Integer)
    product.cartqty = m.cart.deltaOrder(product.code, delta)
    m.AddProducts("cart",m.cart.GetOrder())
end function

' Clear the firmware cart and the script cart category
function store_clear_cart()
    cart = m.cart.GetOrder()
    for each cartproduct in cart
        product = m.allproducts[cartproduct.code]
        product.delete("cartqty")
    end for
    m.cart.ClearOrder()
    if m.products.cart<>invalid then m.products.cart.clear()
end function

