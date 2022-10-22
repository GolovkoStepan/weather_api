module ApiTestsHelper
  def expect_http_status_ok
    expect(last_response.status).to eq(200)
  end

  def json_response
    JSON.parse(last_response.body)
  end

  def expect_json_ok_response
    expect(json_response['status']).to eq('ok')
  end

  def expect_json_error_response
    expect(json_response['status']).to eq('error')
  end

  def expect_json_payload_have(payload)
    expect(json_response).to match(hash_including(payload))
  end
end
