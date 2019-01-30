module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class TimePaymentGateway < Gateway
      require 'nokogiri'
      require 'open-uri'

      #TIME_PAYMENT_USER:     '06BI2WSUSER'
      #TIME_PAYMENT_PASSWORD: 'T34RY757HBWS'
      #TIME_PAYMENT_APPNAME:  'APPLICATION%20PROCESSING'
      #TIME_PAYMENT_HOST:     'http://69.26.125.126'
      def self.login
        user     = ENV['TIME_PAYMENT_USER']      || '06BI2WSUSER'
        password = ENV['TIME_PAYMENT_PASSWORD']  || 'T34RY757HBWS'
        appname  = ENV['TIME_PAYMENT_APPNAME']   || 'APPLICATION%20PROCESSING'
        host     = ENV['TIME_PAYMENT_HOST']      || 'http://69.26.125.126'

        puts "#{user} #{password} #{appname} #{host}"
        uri = URI("#{host}/TimePayment/PaymentService.asmx/Login?as_user=#{user}&as_password=#{password}&as_appname=#{appname}")
        puts uri
        resp = Net::HTTP.get_response(uri)
        @params = Hash.from_xml(resp.body.gsub("\n", ""))
      end

      def self.address_validate(city, state, zip)
        login
        host     = ENV['TIME_PAYMENT_HOST']                || 'http://69.26.125.126'
        session_id = @params["LoginResult"]["SessionID"]

        uri = URI("#{host}/TimePayment/PaymentService.asmx/AddressValidate?sessionID=#{session_id}&City=#{city}&State=#{state}&Zip=#{zip}")
        puts uri
        resp = Net::HTTP.get_response(uri)
        params = Hash.from_xml(resp.body.gsub("\n", ""))
        if params["AddressValidateResult"]["ResponseCode"] == "0"
          return "Address is OK"
        else
          params["AddressValidateResult"]["AddressOptions"]
        end
      end

      def self.get_dealers_and_sales_persons
        login
        host     = ENV['TIME_PAYMENT_HOST']          || 'http://69.26.125.126'
        session_id = @params["LoginResult"]["SessionID"]
        dealer_code = @params["LoginResult"]["DealerCodes"].first[1]

        uri = URI("#{host}/TimePayment/PaymentService.asmx/GetDealersAndSalesPersons?sessionID=#{session_id}&dealercode=#{dealer_code}")
        puts uri
        resp = Net::HTTP.get_response(uri)
        @params = Hash.from_xml(resp.body.gsub("\n", ""))

      end

      def self.get_type_term
        login
        host          = ENV['TIME_PAYMENT_HOST']        || 'http://69.26.125.126'
        session_id    = @params["LoginResult"]["SessionID"]
        dealer_code   = @params["LoginResult"]["DealerCodes"].first[1]

        uri = URI("#{host}/TimePayment/PaymentService.asmx/GetTypeTerm?sessionID=#{session_id}&as_dealercode=#{dealer_code}")
        puts uri
        resp = Net::HTTP.get_response(uri)
        @params = Hash.from_xml(resp.body.gsub("\n", ""))
      end

      def self.add_application(application_id)
        application = Application.find(application_id)

        login
        host        = ENV['TIME_PAYMENT_HOST']       || 'http://69.26.125.126'
        session_id = @params["LoginResult"]["SessionID"]
        dealer_code = @params["LoginResult"]["DealerCodes"].first[1]

        application.Lessee_Fed_ID_Number  = application.Lessee_Fed_ID_Number.gsub("-",'')
        errors = []
        unless application.Lessee_Fed_ID_Number.length == 9
          errors << "Lessee_Fed_ID_Number NEEDS TO BE 9 NUMBERS"
        end

        application.Signer1SSN  = application.Signer1SSN.gsub("-",'')

        unless application.Signer1SSN.length == 9
          if !application.NoGuarantors
            errors << "Signer1SSN NEEDS TO BE 9 NUMBERS"
          end
        end

        valid_lessee_address = address_validate(
            application.LesseeCity,
            application.LesseeState,
            application.LesseeZip,
        )
        unless valid_lessee_address == "Address is OK" ||   valid_lessee_address == nil
          if valid_lessee_address.count == 1
            application.LesseeCity  = valid_lessee_address["AddressInfo"]["City"]
            application.LesseeState = valid_lessee_address["AddressInfo"]["State"]
            application.LesseeZip   = valid_lessee_address["AddressInfo"]["Zip"]
          else
            application.LesseeCity  = valid_lessee_address["AddressInfo"][0]["City"]
            application.LesseeState = valid_lessee_address["AddressInfo"][0]["State"]
            application.LesseeZip   = valid_lessee_address["AddressInfo"][0]["Zip"]
          end
          application.save
          #errors << valid_lessee_address
          puts 'LESEE'
        end

        valid_billing_address = address_validate(
            application.BillingCity,
            application.BillingState,
            application.BillingZip,
        )
        unless valid_billing_address == "Address is OK" ||   valid_billing_address == nil
          if valid_billing_address.count == 1
            application.BillingCity   = valid_billing_address["AddressInfo"]["City"]
            application.BillingState  = valid_billing_address["AddressInfo"]["State"]
            application.BillingZip    = valid_billing_address["AddressInfo"]["Zip"]
          else
            application.BillingCity   = valid_billing_address["AddressInfo"][0]["City"]
            application.BillingState  = valid_billing_address["AddressInfo"][0]["State"]
            application.BillingZip    = valid_billing_address["AddressInfo"][0]["Zip"]
          end
          application.save
          puts 'BILLING'
        end


        valid_signer_address = address_validate(
            application.Signer1City,
            application.Signer1State,
            application.Signer1Zip,
        )
        unless valid_signer_address == "Address is OK" ||  valid_signer_address  == nil
          if valid_signer_address.count == 1
            application.Signer1City  = valid_signer_address["AddressInfo"]["City"]
            application.Signer1State = valid_signer_address["AddressInfo"]["State"]
            application.Signer1Zip   = valid_signer_address["AddressInfo"]["Zip"]
          else
            application.Signer1City  = valid_signer_address["AddressInfo"][0]["City"]
            application.Signer1State = valid_signer_address["AddressInfo"][0]["State"]
            application.Signer1Zip   = valid_signer_address["AddressInfo"][0]["Zip"]
          end
          application.save
          puts 'SIGNER1'
        end

        valid_signer2_address = address_validate(
            application.Signer2City,
            application.Signer2State,
            application.Signer2Zip,
        )
        unless valid_signer2_address == "Address is OK" ||   valid_signer2_address == nil
          if valid_signer2_address.count == 1
            application.Signer2City  = valid_signer2_address["AddressInfo"]["City"]
            application.Signer2State = valid_signer2_address["AddressInfo"]["State"]
            application.Signer2Zip   = valid_signer2_address["AddressInfo"]["Zip"]
          else
            application.Signer2City  = valid_signer2_address["AddressInfo"][0]["City"]
            application.Signer2State = valid_signer2_address["AddressInfo"][0]["State"]
            application.Signer2Zip   = valid_signer2_address["AddressInfo"][0]["Zip"]
          end
          application.save
          puts 'SIGNER2'
        end

        unless errors ==[]
          puts errors
          application.response = errors
          application.save
          return errors
        end

        #login
        session_id = @params["LoginResult"]["SessionID"]
        url = "#{host}/TimePayment/PaymentService.asmx/AddApplication?sessionID=#{session_id}"
        url = url + "&SelectedTypeTerm=#{    application.SelectedTypeTerm}"
        url = url + "&DealerOffice=#{        application.DealerOffic}"
        url = url + "&SalesPerson=#{         }"                             #application.SalesPerson}"
        url = url + "&BasePayement=#{        }"                             #application.BasePayement}"
        url = url + "&OriginalCost=#{        application.OriginalCost}"
        url = url + "&AppType=#{             "B"}"                          #application.AppType}"
        url = url + "&DealerCode=#{           CGI::escape(application.DealerCode)           }"
        url = url + "&BusinessName=#{         CGI::escape(application.BusinessName)         }"
        url = url + "&DBAName=#{              CGI::escape(application.DBAName)              }"
        url = url + "&LesseeStreet1=#{        CGI::escape(application.LesseeStreet1)        }"
        url = url + "&LesseeStreet2=#{        CGI::escape(application.LesseeStreet2)        }"
        url = url + "&LesseeCity=#{           CGI::escape(application.LesseeCity)           }"
        url = url + "&LesseeState=#{          CGI::escape(application.LesseeState)          }"
        url = url + "&LesseeZip=#{            CGI::escape(application.LesseeZip)            }"
        url = url + "&LesseePhone=#{          CGI::escape(application.LesseePhone)          }"
        url = url + "&LesseeYRB=#{            CGI::escape(application.LesseeYRB)            }"
        url = url + "&LesseeEmail=#{          CGI::escape(application.LesseeEmail)          }"
        url = url + "&BillingName=#{          CGI::escape(application.BillingName)          }"
        url = url + "&BillingStreet1=#{       CGI::escape(application.BillingStreet1)       }"
        url = url + "&BillingStreet2=#{       CGI::escape(application.BillingStreet2)       }"
        url = url + "&BillingCity=#{          CGI::escape(application.BillingCity)          }"
        url = url + "&BillingState=#{         CGI::escape(application.BillingState)         }"
        url = url + "&BillingZip=#{           CGI::escape(application.BillingZip)           }"
        url = url + "&Dealer_reference=#{     CGI::escape(application.Dealer_reference)     }"
        url = url + "&Lessee_Fed_ID_Number=#{ CGI::escape(application.Lessee_Fed_ID_Number) }"
        url = url + "&DealerReference=#{      CGI::escape(application.DealerReference)      }"
        url = url + "&LesseeFedIDNumber=#{    CGI::escape(application.LesseeFedIDNumber)    }"
        url = url + "&NoGuarantors=#{         application.NoGuarantors                      }"
        url = url + "&Signer1Name=#{          CGI::escape(application.Signer1Name)          }"
        url = url + "&Signer1SSN=#{           CGI::escape(application.Signer1SSN)           }"
        url = url + "&Signer1DOB=#{           CGI::escape(application.Signer1DOB)           }"
        url = url + "&Signer1HomePhone=#{     CGI::escape(application.Signer1HomePhone)     }"
        url = url + "&Signer1WorkPhone=#{     CGI::escape(application.Signer1WorkPhone)     }"
        url = url + "&Signer1Employer=#{      CGI::escape(application.Signer1Employer)      }"
        url = url + "&Signer1Title=#{         CGI::escape(application.Signer1Title)         }"
        url = url + "&Signer1Email=#{         CGI::escape(application.Signer1Email)         }"
        url = url + "&Signer1Addr1=#{         CGI::escape(application.Signer1Addr1)         }"
        url = url + "&Signer1Addr2=#{         CGI::escape(application.Signer1Addr2)         }"
        url = url + "&Signer1City=#{          CGI::escape(application.Signer1City)          }"
        url = url + "&Signer1Zip=#{           CGI::escape(application.Signer1Zip)           }"
        url = url + "&Signer1State=#{         CGI::escape(application.Signer1State)         }"
        url = url + "&Signer1OwnwRes=#{       CGI::escape(application.Signer1OwnwRes)       }"
        url = url + "&Signer1Year=#{          CGI::escape(application.Signer1Year)          }"
        url = url + "&Signer2Name=#{          CGI::escape(application.Signer2Name)          }"
        url = url + "&Signer1PercentOwner=#{  CGI::escape(application.Signer1PercentOwner)  }"
        url = url + "&Signer2SSN=#{           CGI::escape(application.Signer2SSN)           }"
        url = url + "&Signer2DOB=#{           CGI::escape(application.Signer2DOB)           }"
        url = url + "&Signer2HomePhone=#{     CGI::escape(application.Signer2HomePhone)     }"
        url = url + "&Signer2WorkPhone=#{     CGI::escape(application.Signer2WorkPhone)     }"
        url = url + "&Signer2Employer=#{      CGI::escape(application.Signer2Employer)      }"
        url = url + "&Signer2Title=#{         CGI::escape(application.Signer2Title)         }"
        url = url + "&Signer2Email=#{         CGI::escape(application.Signer2Email)         }"
        url = url + "&Signer2Addr1=#{         CGI::escape(application.Signer2Addr1)         }"
        url = url + "&Signer2Addr2=#{         CGI::escape(application.Signer2Addr2)         }"
        url = url + "&Signer2City=#{          CGI::escape(application.Signer2City)          }"
        url = url + "&Signer2Zip=#{           CGI::escape(application.Signer2Zip)           }"
        url = url + "&Signer2State=#{         CGI::escape(application.Signer2State)         }"
        url = url + "&Signer2OwnwRes=#{       CGI::escape(application.Signer2OwnwRes)       }"
        url = url + "&Signer2Year=#{          CGI::escape(application.Signer2Year)          }"
        url = url + "&Signer2PercentOwner=#{  CGI::escape(application.Signer2PercentOwner)  }"
        uri = URI(url)
        puts ''
        puts ''
        puts ''
        puts url
        puts ''
        puts ''
        puts ''
        resp = Net::HTTP.get_response(uri)
        #@params = Hash.from_xml(resp.body.gsub("\n", ""))
        #application.response = {code: @params["AddAppResult"]["AddressLookUp"]["ResponseCode"], LogMessage: @params["AddAppResult"]["AddressLookUp"]["LogMessage"]}
        application.response = resp.body
        application.save
        begin
          hash = Hash.from_xml(resp.body.gsub("\n", ""))
          if hash["AddAppResult"].present? && hash["AddAppResult"]["AppNumber"].present?
            application.response = hash["AddAppResult"]["AppNumber"]
            if hash["AddAppResult"]["AppNumber"].present?
              application.is_time_approved = true
            end
            application.save

          elsif hash["AddAppResult"]["ErrorMessage"].present?
            application.response = hash["AddAppResult"]["ErrorMessage"]
            application.is_time_approved = false
            application.save
          end
        rescue
        end

        resp.body
      end


      def self.test
        ## CC
        good_url = "http://69.26.125.126/TimePayment/PaymentService.asmx/AddApplication?sessionID=03305e6b-13b2-4c1d-99c6-60bc41578b4e&SelectedTypeTerm=COMM LTO|21 MONTHS|ON1P2|E|B&DealerOffice=0&SalesPerson=&BasePayement=&OriginalCost=9999&AppType=B&DealerCode=06BI2&BusinessName=Amberlea Jean Haessly&DBAName=The Wedding Florist&LesseeStreet1=901 s poplar st&LesseeStreet2=&LesseeCity=Northfield&LesseeState=MN&LesseeZip=55057&LesseePhone=5075812277&LesseeYRB=1&LesseeEmail=weddingfloristmn@hotmail.com&BillingName=Amberlea Jean Haessly&BillingStreet1=901 s poplar st&BillingStreet2=&BillingCity=Northfield&BillingState=MN&BillingZip=55057&Dealer_reference=&Lessee_Fed_ID_Number=824371715&DealerReference=&LesseeFedIDNumber=824371715&NoGuarantors=false&Signer1Name=AMBERLEA HAESSSLY&Signer1SSN=472117512&Signer1DOB=&Signer1HomePhone=5075812277&Signer1WorkPhone=5075812277&Signer1Employer=&Signer1Title=Owner&Signer1Email=theweddingfloristmn@hotmail.com&Signer1Addr1=901 S Poplar St&Signer1Addr2=&Signer1City=Northfield&Signer1Zip=55057&Signer1State=MN&Signer1OwnwRes=&Signer1Year=&Signer2Name=&Signer1PercentOwner=&Signer2SSN=&Signer2DOB=&Signer2HomePhone=&Signer2WorkPhone=&Signer2Employer=&Signer2Title=&Signer2Email=&Signer2Addr1=&Signer2Addr2=&Signer2City=&Signer2Zip=&Signer2State=&Signer2OwnwRes=&Signer2Year=&Signer2PercentOwner="


        ## CC_uRL
        bad_url = "http://69.26.125.126/TimePayment/PaymentService.asmx/AddApplication?sessionID=f23241af-b459-43b5-a08b-ce7f83b9fa69&SelectedTypeTerm=COMM LTO|21 MONTHS|ON1P2|E|B&DealerOffice=0&SalesPerson=&BasePayement=&OriginalCost=9999&AppType=B&DealerCode=06BI2&BusinessName=Amberlea Jean Haessly&DBAName=The Wedding Florist&LesseeStreet1=901 s poplar st&LesseeStreet2=&LesseeCity=Northfield&LesseeState=MN&LesseeZip=55057&LesseePhone=5075812277&LesseeYRB=1&LesseeEmail=wedding@hotmail.com&BillingName=Amberlea Jean Haessly&BillingStreet1=901 s poplar st&BillingStreet2=&BillingCity=Northfield&BillingState=MN&BillingZip=55057&Dealer_reference=&Lessee_Fed_ID_Number=824371715&DealerReference=&LesseeFedIDNumber=824371715&NoGuarantors=false&Signer1Name=AMBERLEA HAESSSLY&Signer1SSN=472117512&Signer1DOB=&Signer1HomePhone=5075812277&Signer1WorkPhone=5075812277&Signer1Employer=&Signer1Title=Owner&Signer1Email=theweddingfloristmn@hotmail.com&Signer1Addr1=901 S Poplar St&Signer1Addr2=&Signer1City=Northfield&Signer1Zip=55057&Signer1State=MN&Signer1OwnwRes=&Signer1Year=&Signer2Name=&Signer1PercentOwner=&Signer2SSN=&Signer2DOB=&Signer2HomePhone=&Signer2WorkPhone=&Signer2Employer=&Signer2Title=&Signer2Email=&Signer2Addr1=&Signer2Addr2=&Signer2City=&Signer2Zip=&Signer2State=&Signer2OwnwRes=&Signer2Year=&Signer2PercentOwner="


        good_split = good_url.split("&")
        bad_split  = bad_url.split("&")
        (0..60).each do |t|
          unless good_split[t] == bad_split[t]
            puts good_split[t]
            puts bad_split[t]
            puts ' ^^  '
          else
            # puts good_split[t]
            # puts bad_split[t]
            # puts ' --  '
          end
        end
      end
    end
  end
end
