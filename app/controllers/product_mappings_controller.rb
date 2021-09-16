class ProductMappingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product_mapping, only: %i[ show update destroy ]

  def index
    if params[:product_mapping] == 'Ebay Sandbox'
      require 'uri'
      require 'net/http'

      url = ('https://api.sandbox.ebay.com/sell/inventory/v1/inventory_item?offset=0')
      params = { :limit => 10, :page => 3 }
      headers = { 'authorization' => 'Bearer <v^1.1#i^1#f^0#I^3#r^0#p^1#t^H4sIAAAAAAAAAOVYa2wURRzv9dpieQgGU0FIOBeEKO7ePnqvtXdybaGtlGvhrpU2MTi7O9cu3dtdd2ZpD0KohRREEpFo1KAJUUmE8AE/GCIp+EpMIYYEJRLBYCSGaNVIAopGBef2SrlWAi09YxPvy97M/J+/+T9mhu0uKX24t7b3yjTXpMI93Wx3ocvFTWFLS4oX3+0uvL+4gM0hcO3pXtBd1OP+rgKBlGaKqyAyDR1BT1dK05HoTIYp29JFAyAViTpIQSRiWYxHV9SLPMOKpmVgQzY0ylNXHaZgCCpKoFxOBmQIAoAns/p1mQkjTAmCzxdU+IAc9CmKLCtkHSEb1ukIAx2HKZ7lOZoN0ZwvwbGiLyQKRIcgtFKeZmgh1dAJCcNSEcdc0eG1cmy9takAIWhhIoSK1EWXxRuiddVLY4kKb46syCAOcQywjYaPqgwFepqBZsNbq0EOtRi3ZRkiRHkjWQ3DhYrR68bcgfkO1HIQKpyfl/wyGwr4FT4vUC4zrBTAt7YjM6MqdNIhFaGOVZy+HaIEDWktlPHgKEZE1FV7Mp+VNtDUpAqtMLW0MtoSbWykIlXtQNehVk0P/YlXrqYh4IPlIUmSaBAEvhBQhEFFWWmDMI/QVGXoipoBDXliBq6ExGo4EpvyHGwIUYPeYEWTOGNRLh1/HUM+1JrZ1Owu2rhdz+wrTBEgPM7w9jswxI2xpUo2hkMSRi44EIUpYJqqQo1cdGJxMHy6UJhqx9gUvd7Ozk6mU2AMq83LsyznXb2iPi63wxSgCG0m17P06u0ZaNVxRYaEE6kiTpvEli4Sq8QAvY2KCAHOXx4axH24WZGRs/+YyPHZOzwj8pUhXDDJk0rE+/2cIHH5KTaRwSD1ZuyAEkjTKWB1QGxqQIa0TOLMTkFLVUTBl+SFYBLSij+UpMtDySQt+RQ/zSUhZCGUJDkU/D8lymhDPQ5lC+K8xHre4jyqrWiqaSlPVykt9Y31Rr0ZWN/CNgSisVhjYGlCKF8cX1nTbrFCMhYMjzYbbup8laYSZBJEfz4AyOR6/kCoNRCGyrjci8uGCRsNTZXTE2uDBUtpBBZOV9ppMo5DTSOfcbkaNc26/FTsvDk5xmJxZ37nr1P9R13qpl6hTOBOLK8y/IgIAKbKkD6UyfU0IxsprwHIISQzvcax2jOC8KZEXslOM202RJhYopBz4KiZVFLMGdLSlNGzZBsmcWL0LOSSodgyviNFTmdmCJpqWztGY9LZNR5QJFvrGFfQqeTyMKFCjrib9VtVsqd+xnGeQetkxoLIsC1y4WEaMofghNEBdXKkwJahadBq5sZdTFMpGwNJgxOtquahuqhgbOedoh7X8X/dL84vcAFW8AX4cfkmOyeaNROtJ+S7F47hbuMd/tISKXB+XI/rCNvjeq/Q5WIDLM0tZh8qcTcVuadSiFQTBgFdkYwuRgVJhhQyHWDbgkwHTJtAtQpLXOqZU/JvOW88e55kZw298pS6uSk5Tz7s3Bsrxdz0+6bxHBvifBzrCwl8Kzv/xmoRV1Z0r2vDUxtnbfukrGare0akqgztanzZx04bInK5igtIQBbM3/38F4sGKPYx1Lp7R2tf8cKIvHaLUtp07vu3zry0e9P7O15798hZq7dvaqzu8IPFXbHNk09Xln1wYZfmfeTx/c80R66d6Dnz8bd9py6slw/GZv9V0DAH0e6ztZ/VGIsu7Xu9lN1+z8FjiSXb1j7Q99XF5VsaCpefO3D4MPpz85yrfqZfmJ7s//DHhVffflXZcejo3rYX6ucu3HfsiXfkn7++FP6lY/+SgU837mLVp2O9VtObq6vXXeyfVzDvQMg8/+gibtOqn2Ze3PvrDwM+NPPQydpgRRX9+SuTft/50ew1b+xUj86c/uWVEzNaLy+4q7vsGHf8Wis98NyL9VtPblh2/uCzky/3rzpd8ccFy/tNdhv/Br8j95l9EwAA>',
                  'accept-language' => 'en-US'}
      # uri.query = URI.encode_www_form(params)
      # res = Net::HTTP.get_response(uri)
      # puts res.body if res.is_a?(Net::HTTPSuccess)
      uri = URI(url)
      request = Net::HTTP.get_response(uri, headers)

      # request.body = request # SOME JSON DATA e.g {msg: 'Why'}.to_json

      # response = http.request(request)

      @body = JSON.parse(request.body) # e.g {answer: 'because it was there'}

      respond_to do |format|
        format.html
      end
    end
  end

  def show
  end

  def new
  end

  def edit
  end

  def create
  end

  def update
  end

  def destroy
  end

  private
    def product_mapping_params
    end
end
