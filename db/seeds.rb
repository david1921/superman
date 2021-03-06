Country.delete_all
Country.create(:name => 'United States', :code => 'US',
               :postal_code_regex => '\A\d{5}[-]{0,1}(\d{4})?\z',
               :phone_number_length => 10,
               :calling_code => '1')
Country.create(:name => 'Canada', :code => 'CA',
               :postal_code_regex => '^\D{1}\d{1}\D{1}[-\s]{0,1}\d{1}\D{1}\d{1}$',
               :phone_number_length => 10,
               :calling_code => '1')
Country.create(:name => 'United Kingdom', :code => 'UK',
               :postal_code_regex => '[A-Z]{1,2}[0-9R][0-9A-Z]? [0-9][ABD-HJLNP-UW-Z]{2}\z',
               :phone_number_length => 11,
               :calling_code => '44')
