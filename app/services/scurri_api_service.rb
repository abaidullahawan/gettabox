# frozen_string_literal: true

# Api calls of scurri api
class ScurriApiService

  def self.create_shipment(url, body, auth)
    response = post_scurri_api(url, body, auth)
    sleep 5
    return_response(response)
  end

  def self.consignment_document(url, auth)
    response = get_scurri_api(url, auth)
    sleep 5
    return_response(response)
  end

  def self.post_scurri_api(url, body, auth)
    HTTParty.post( url,
    headers: {
      'Authorization' => auth,
      'content-type' => 'application/json'
    },
    body: body.to_json)
  end

  def self.get_scurri_api(url, auth)
    HTTParty.send(
       :get, url,
       headers: {
         'Authorization' => auth
       }
    )
  end

  def self.delete_scurri_api

  end

  def self.return_response(result)
    return { status: true, body: JSON.parse(result.body) } if result.success?

    { status: false, error: result['error_description'] }
  end
end