# frozen_string_literal: true

module OrderDispatchesHelper # :nodoc:
  def postage_mapping(postage)
    postage_hash = {'Standard' => '0.0', 'SecondDay' => '2.99', 'Expedited' => '2.99'}

    return postage if postage.to_f.to_s.eql? postage

    postage_hash[postage]
  end
end
