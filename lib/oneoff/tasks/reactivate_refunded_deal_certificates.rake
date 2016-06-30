namespace :oneoff do

  task :reactivate_refunded_deal_certificates => :environment do

    dry_run = ENV["DRY_RUN"].present?

    serial_numbers = %w(
      5608-9627
      9253-7542
      5364-0235
      0780-5501
      1734-5892
      7445-8831
      9302-3325
      4510-3555
      7690-3407
      7309-1673
      8013-0694
      5194-1575
      8443-8818
      8301-5831
      4803-6190
      2086-5369
      4344-0567
      5168-1499
      6400-1893
      0689-6572
      3392-4864
      9904-2849
      5160-2956
      7248-5066
      8489-5095
      4155-6735
      6554-5712
      4770-9818
      4605-7578
      8485-0884
      8233-7289
      9779-6885
      0513-0538
      4320-1599
      0579-8025
      6138-3791
      3900-9472
      4462-2580
      1546-6910
      9574-0091
      7653-1269
      1275-3646
      2152-3968
      1896-6572
      2585-8228
      8407-1448
      9319-0950
      2750-1241
      0258-1353
      1870-6670
      5596-9676
      6845-9794
      8387-4539
      5494-7696
      0281-0649
      4839-7294
      1288-4424
      6531-9612
      6743-1921
      6361-5539
      7597-1486
      4422-3555
      0624-1087
      5177-0060
      3518-3190
      2451-5165
      6782-0336
      8485-3434
      2800-3654
      5313-0667
      7510-7978
      9869-4108
      1984-1640
      3190-6106
      9547-5250
      8655-1089
      7752-3465
      4141-2144
      7662-1808
      9594-3383
      1668-1180
      0889-3909
      1064-5675
      3227-3767
      8741-4179
      7105-7646
    )
    
    purchased_gift_certs = PurchasedGiftCertificate.find_all_by_serial_number(serial_numbers)
    puts "found #{purchased_gift_certs.count} certificates to reactivate" if dry_run
    
    num_updated = 0
    purchased_gift_certs.each do |pgc|
      if dry_run
        puts "** dry run, not updating ** Reactivating #{pgc.serial_number}"
      else
        puts "Reactivating #{pgc.serial_number}"
        pgc.update_attribute :payment_status, "completed"
      end
      num_updated += 1
    end
    
    if dry_run
      puts "** dry run, not updating ** #{num_updated} deal certificates reactivated"
    else
      puts "#{num_updated} deal certificates reactivated"
    end
  end

end