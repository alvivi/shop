defmodule Shop.Discounts.Bulk do
  @moduledoc """
  Discounts applied on bulk purchases

  A Discount that is applied on bulk purchases, i.e., buy x or more of the same
  product a get a reduced product price.

  See `Shop.DiscountKind` for more information about how to use discounts.

  The parameters needed to run this discount are:

    * `product` `String`: The product code where the discount applies.
    * `count` `Number`: The number of products that the client have to buy in
      order to apply the discount.
    * `price` `Number`: The new price of the product.

  """
  @behaviour Shop.DiscountKind

  alias Shop.{Checkout, Product}

  @impl true
  def spec() do
    %{
      description: "Buy X of the same product, get a special product price",
      parameters: [
        %{
          id: :product,
          kind: :string,
          description: "The product code where the discount applies"
        },
        %{
          id: :count,
          kind: :number,
          description: """
            The number of products that the client have to buy in order to apply
            the discount
          """
        },
        %{
          id: :price,
          kind: :number,
          description: """
            The new price of the product. If this value is a integer then prices
            are set to this value. If this value is a float then this value is
            apply as factor of the original price.
          """
        }
      ]
    }
  end

  @impl true
  def apply(%{count: count}, checkout) when count <= 0, do: checkout

  @impl true
  def apply(%{count: count, product: product} = params, %Checkout{items: item_list} = checkout) do
    product_count = Enum.count(item_list, &Kernel.==(product, &1.code))

    if product_count < count do
      checkout
    else
      updated_item_list =
        Enum.map(item_list, fn
          %Product{code: ^product} = item -> apply_discount(params, item)
          item -> item
        end)

      %Checkout{checkout | items: updated_item_list}
    end
  end

  @impl true
  def name(%{count: count}), do: "Bulk +#{count}"

  defp apply_discount(%{price: discount} = params, product) do
    extra = product.extra || %{}

    %Product{
      product
      | price: compute_price(product.price, discount),
        extra: Map.merge(extra, %{discount: name(params), original_price: product.price})
    }
  end

  defp compute_price(_price, discount) when is_integer(discount), do: discount
  defp compute_price(price, discount), do: ceil(price * discount)
end
