require 'lib/oneoff/groucher_import'

namespace :oneoff do
  namespace :groucher do

    # This tasks expect a file with the format
    #"ID,UserFName,UserLName,Email,encPassword,RegistrationDate,CityName"
    #"104207,Gerardo,Argueta,email@hotmail.com,password,6/20/2012 11:53:27 PM,Fox Cities"
    desc "Import users for publishers grouchercom fox city and green bay. The users's file should have rows with ID, UserFName, UserLName, Email, Password, RegistrationDAte, CityNAme"
    task :import_users => :environment do
      dry_run   = ENV['DRY_RUN'].present?
      file_path = ENV['FILE_PATH']

      raise "The file #{file_path} with the users to import does not exist." unless File.exists?(file_path)

      GroucherImport.users(file_path, dry_run)
    end # users  task

    # This tasks expect a file with the format
    #"City,Groucher Title,Description,Company,Company Phone,Offer $ Value,Offer $ Price,Expiration Date,PurchasesID,CustomerName,email,Phone,CouponUniqueID,DTCreated,DTClaimed,QTy,TransactionStatus"
    #"Fox Cities,Kidz Town,Buy one admission and get one free at Kidz Town  Let your kids go to town!,Kidz Town,920-434-1234,16,8,6/27/2012,7870,NAZE, LUANN,lmnaze@yahoo.com,,1326-3828,12/31/2011 6:00:01 AM,,2,5"
    desc "Import vouchers for publishers grouchercom fox city and green bay. City,Groucher Title,Description,Company,Company Phone,Offer $ Value,Offer $ Price,Expiration Date,PurchasesID,CustomerName,email,Phone,CouponUniqueID,DTCreated,DTClaimed,QTy,TransactionStatus."
    task :import_vouchers => :environment do
      dry_run       = ENV['DRY_RUN'].present?
      file_path     = ENV['FILE_PATH']
      vouchers_path = ENV['VOUCHERS_PATH']

      raise "The file #{file_path} with the vouchers to import does not exist." unless File.exists?(file_path)
      raise "The path #{vouchers_path} with the vouchers to import does not exist." unless File.exists?(vouchers_path)

      GroucherImport.vouchers(file_path, vouchers_path, dry_run)
    end # voucher task

  end
end
