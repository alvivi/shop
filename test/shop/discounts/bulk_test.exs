defmodule ShopTest.Discounts.Bulk do
  use Shop.Case, async: true

  alias Shop.{Checkout, Discounts.Bulk, Product}

  property "does nothing when applied to a non-existing product" do
    forall checkout <- checkout(item_codes: ~w(bar qux)) do
      checkout_after_discount = Bulk.apply(%{count: 1, price: 0, product: "foo"}, checkout)
      checkout_after_discount == checkout
    end
  end

  property "does nothing when count is equal or less than zero" do
    forall [checkout <- checkout(item_codes: ~w(foo bar qux)), count <- neg_integer()] do
      checkout_after_discount = Bulk.apply(%{count: count, price: 0, product: "foo"}, checkout)
      checkout_after_discount == checkout
    end
  end

  property "does nothing when the available product are less than count" do
    forall checkout <- checkout(item_codes: ~w(foo bar qux)) do
      count = Enum.count(checkout.items, &Kernel.==("foo", &1.code))

      checkout_after_discount =
        Bulk.apply(%{count: count + 1, price: 0, product: "foo"}, checkout)

      checkout_after_discount == checkout
    end
  end

  property "checkout price is always lower or equal than without discount (upper bound)" do
    forall checkout <- checkout(non_empty: true, free_items: false, item_codes: ~w(foo bar qux)) do
      checkout_after_discount = Bulk.apply(%{count: 1, price: 0, product: "foo"}, checkout)
      Checkout.price(checkout_after_discount) <= Checkout.price(checkout)
    end
  end

  property "price is always equal or greater than all-in discount (lower bound)" do
    forall checkout <- checkout(non_empty: true, free_items: false, item_codes: ~w(foo bar qux)) do
      checkout_after_discount = Bulk.apply(%{count: 1, price: 0, product: "foo"}, checkout)

      checkout_no_foo = %Checkout{
        checkout
        | items: Enum.reject(checkout.items, &("foo" == &1.code))
      }

      Checkout.price(checkout_after_discount) >= Checkout.price(checkout_no_foo)
    end
  end

  test "discount attach extra information" do
    coffee = Product.new("CF1", "Coffee", 1123)

    checkout =
      "checkout"
      |> Checkout.new()
      |> Checkout.add_product(coffee)
      |> Checkout.add_product(coffee)

    discount = %{count: 2, price: 0, product: "CF1"}

    product_discount =
      discount
      |> Bulk.apply(checkout)
      |> Map.get(:items)
      |> Enum.at(1)
      |> Map.get(:extra)
      |> Map.get(:discount)

    assert product_discount == Bulk.name(discount)
  end
end
