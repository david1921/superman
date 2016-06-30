namespace :oneoff do
  desc "adds signup credits for the initial timewarner cable pubilshers consumers"
  task :add_signup_discounts_for_initial_timewarnercable_consumers do
    
    setup_data  = {
      "clickedin-austin" => {
        "emails" => ["benmettin@gmail.com","hhh99@austin.rr.com","goodwlldrumming@hotmail.com","texas_wassail@yahoo.com","arindam3110@gmail.com","bscrimgeour@austin.rr.com","cwalls@austin.rr.com","meholloway@earthlink.net","AngieMeisenholder@yahoo.com","dmfarlough@gmail.com","cscarrillo@gmail.com","bobsaxreynolds@yahoo.com","mharris1@austin.rr.com","dayne21017@yahoo.com","ecbeil@austin.rr.com","mlheisterman@gmail.com","julescota@aol.com","gjllilley@gmail.com","opina1@austin.rr.com","send2tray@yahoo.com","grantdonan@gmail.com","k1707@austin.rr.com","salesberryj1@hotmail.com","daniellic@hotmail.com","ednichanian@hotmail.com","Keithaustx@yahoo.com","daniel.j.hernandez@gmail.com","jasbramsey@yahoo.com","jkhughes+clickedin@gmail.com","betty.reeves@att.net","ljjfire67@live.com","Garces@datafoundry.com","kathryn.houser@solarprofessional.com","Getback2work9@yahoo.com","cby@io.com","chad@planetjames.com","keith.malan@ni.com","jesimpkins08@gmail.com","ammtz8@gmail.com","bandabecky@yahoo.com","slgalarz23@yahoo.com","tplant5@austin.rr.com","Khgiblin@gmail.com","hostastudentcci@gmail.com","S_medina@Austin.rr.com","kchill18@yahoo.com","Kfinwauk@aol.com","irhee@yahoo.com","dwslx1@gmail.com","debbieh815@yahoo.com","Rejukg@gmail.com","scarletbrand@yahoo.com","d4rtx@aol.com","tre_rena@hotmail.com","Jkim1128@yahoo.co.kr","ebissett@austin.rr.com","howdymc@aol.com","ditti82@earthlink.net","cmcbride001@austin.rr.com","joell_engelke@yahoo.com","dcalhoun@austin.rr.com","randryoung22@sbcglobal.net","lisaw0525@yahoo.com","Adamsolis@ymail.com","Smendoza1416@gmail.com","Hotasiancrmel@gmail.com","jorgina.sanders@yahoo.com","klpurvis@earthlink.net","geevilla2@yahoo.com","rtolworthy@gmail.com","liz.brannen@gmail.com","texas2001@hotmail.com","rbtanner@austin.rr.com","bevo1bevo2@yahoo.com","nemetz.craig@gmail.com","suecewan@gmail.com","grandmagela139@gmail.com","renegarza101@yahoo.com","esroop@gmail.com","sapodac@Austin.rr.com","ansrivas@gmail.com","smhood27_07@hotmail.com","Cjwilson88@gmail.com","ambotello@gmail.com","Ycdavila15@hotmail.com","gczepiel@austin.rr.com","mwagner13@msn.com","laurengaller@hotmail.com","LMayhew@austin.rr.com","ismith7381@austin.rr.com","Julieh@ncua.gov","wgillman@jdabrams.com","muirbroj@southwestern.edu","gbaglia@gmail.com","betybobety@gmail.com","mhammar@austin.rr.com","greggr@austin.rr.com","mcjfaulkner@hotmail.com","utgrad28@yahoo.com","pholmes1@austin.rr.com","cmalies2@gmail.com","no@email.com","hchambers@austin.rr.com","james140@gmail.com","simon.guardiola@hotmail.com","bretsweeney@yahoo.com","nancy.tripp@co.travis.tx.us","thomas.suhr@lamrc.com","johnmattox@austin.rr.com","tami417@austin.rr.com","ars53009@aim.com","robwalker@austin.rr.com","pattydonaghy@gmail.com"]
      },
      "clickedin-dallas" => {
        "emails" => ["s.spin@tx.rr.com","Didancerkatie@Mac.com","lmorg82@gmail.com","kc_ladyboss@yahoo.com","djsupreme66@gmail.com","pskreddy@gmail.com","www.cowboys08@yahoo.com","liz15mex@yahoo.com","numairchoudhury@hotmail.com","javier.guillermo@gmail.com","mmkollar@me.com","Trevino214@gmail.com","frk_rz_131@yahoo.com","jkim60@tx.rr.com","eyruiz1@yahoo.com","annmcortez@gmail.com","llorch@lorchproductions.com","laquita94@gmail.com","kommando0@yahoo.com","caligirltexasluv@yahoo.com","mehgan.price@yahoo.com","Marielardz31@gmail.com","lsch_2008@yahoo.com","alexpedraza@msn.com","classiclamppost@yahoo.com","mehrab012@yahoo.com","rohit.kamal@gmail.com","dorisann1113@yahoo.com","gerald.elsa@sbcglobal.net","mike55mass@tx.rr.com","Pprice7@Tx.rr.com","dlnettles08@yahoo.com","ccalk48@gmail.com","brian@idjn.net","mrbigking44@yahoo.com","genesisgkh@tx.rr.com","maritzasalazar6@aol.com","eskael1975@gmail.com","timdaniels957@gmail.com","cldenterprises@gmail.com","knbagri@hotmail.com","gene@fallert.net","N.blaylock@gmail.com","ClickedIn@n5gar.com","Jessi2600@yahoo.com","sree40@hotmail.com","bshrew10@yahoo.com","margravemark@gmail.com","rodpate@tx.rr.com","h.joset@yahoo.com","bmeadows1@tx.rr.com","chrisbarnes70@msn.com","akualiz@yahoo.com","enacardona@sbcglobal.net","Cakelady_02@yahoo.com","dorofromtexas@yahoo.com","alindblom@sbcglobal.net","la.mich@hotmaiol.com","marmijo_02@yahoo.com","lmcghee@hotmail.com","mriveradallas@hotmail.com","dsudhakar26@gmail.com","halton65@yahoo.com","juanmbenitez1@hotmail.com","DPangy@aol.com","Jazziclassigurl07@yahoo.com","Bnoiel95@gmail.com","bowens@alpha-dallas.net","joshjames85@gmail.com","asj5062@yahoo.com","kellytilghman@yahoo.com","kdinzer@yahoo.com","thebrooksfamily@hotmail.com","kpp4078@yahoo.com","gabbie52tkej@yahoo.com","judyhula@yahoo.com","lillyt1609@yahoo.com","rd143@tx.rr.com","dolphinglass@yahoo.com","bitshardman@tx.rr.com","mark.buford@live.com","moosifer70@yahoo.com","jimmoy2@yahoo.com","lisa@freelisa.com","shelia.j.feathers@ssa.gov","chudiburg@yahoo.com","Jrex1182@gmail.com","tenchafragoso@yahoo.com","anneb972@sbcglobal.net","subhankar.sahu@yahoo.co.in","kcrome@aol.com","Vallisellers@hotmail.com","esantoyo1@yahoo.com","maryann_herin@yahoo.com","lizardgio@gmail.com","theresasauced50@yahoo.com","kari.pratt@att.net","jmzoll01@yahoo.com","irisbrown@hotmail.com","Crazymarty77@yahoo.com","nikhilv999@gmail.com","jitenderarora2003@yahoo.co.in","reinatexas@yahoo.com","jbm109@gmail.com","jcorderotx@yahoo.com","reneewright1227@yahoo.com","alicelyang@gmail.com","johnelias823@hotmail.com","sam9292@att.net","blinderyy@gmail.com","xuepingx@gmail.com","xxuepingye1@gmail.com","xpingxye@gmail.com","kpolozeck@tx.rr.com","TigerAKA@aol.com","dallasdeb123@yahoo.com","manderson9999@excite.com","yisa99@hotmail.com","ryohoshi1985@yahoo.com","klparrish1@msn.com","freeney@conceptsvcs.com","drewdad22@gmail.com"]
      },
      "clickedin-sanantonio" => {
        "emails" => ["lmitchell@satx.rr.com","scottastephens@satx.rr.com","vcurtis@satx.rr.com","RDRAHEIMJR@satx.rr.com","rdraheim@netzero.net","rdraheim@netzero.com","greenmount430@gmail.com","erivas8@satx.rr.com","rjanzen@satx.rr.com","csalas3@satx.rr.com","hrhdoha@gmail.com","bridgetqr@yahoo.com","JTCTX@SATX.RR.COM","thepfeiffer@satx.rr.com","shearleyaf@satx.rr.com","hskeldon@satx.rr.com","brall@satx.rr.com","betaking@live.com","pllanas@satx.rr.com","rgarcia5828F@satx.rr.com","flipside252@yahoo.com","ccbat51@gmail.com","davislipeng@gmail.com","Gaga735@aol.com","Jimmeadows2@gmail.com","gkrueger1@satx.rr.com","jcano11@satx.rr.com","varadharaja@gmail.com","lra0125@hotmail.com","mfcurry@satx.rr.com","krollston@satx.rr.com","rachelanneblack@gmail.com","chadgbgnavy@aol.com","rsekhar@live.com","dianaolack@sbcglobal.net","Jhansbrough@satx.rr.com","Mario@fuzionsystems.net","terry.resop@gmail.com","decyd@decyd.com","gwenjohnson46@aol.com","zimmy448@yahoo.com","Sarahmeckel@mail.com","celrngl@yahoo.com","pft@stic.net","simirah37@yahoo.com","gomezmary@sbcglobal.net","carl@cilsoftware.com","mrslisawhite@yahoo.com","lfantasia@satx.rr.com","aemtz91@yahoo.com","ivanrl08@gmail.com","carlibee@gmail.com","dlove81@satx.rr.com","carlevarom@aol.com","cgrammer@satx.rr.com","jsmetzer@satx.rr.com","mrsadelina@hotmail.com","patricia_bessner@yahoo.com","S.sendejo@hotmail.com","szamora@tridentinsurance.net","jdiv3@hotmail.com","donald.hudson@va.gov","corliss1@earthlink.net","arathgeber@satx.rr.com","jjmartinez@satx.rr.com","hkhughes76@gmail.com","angela.sanchez@valero.com","guzman47@att.net","dkittelson@satx.rr.com","aggie.amanda@yahoo.com","eslater99@yahoo.com","cmadden75@hotmail.com","Missycastillo@ymail.com","jpcouncil@satx.rr.com","Alexz1105@yahoo.com","ktlynn2005@hotmail.com","gabriel.griego62@gmail.com","maddhatter00@gmail.com","Morales.diana67@yahoo.com","Greatsmile417@aol.com","shanelanford@gmail.com","jmdmabad@gmail.com","alaniz-82@hotmail.com","wrogers1@satx.rr.com","Pablo_Ortiz2007@yahoo.com","Nguyengiao83@gmail.com","Badukes35@att.net","lisa.d.gonzales@wellsfargo.com","rulouadams@yahoo.com","smsolis@satx.rr.com","star_lit_smile@yahoo.com","mizpat1929@yahoo.com","Mayoerica@ymail.com","valeriet21@yahoo.com","pia.norori@Gmail.com","ajeffers@satx.rr.com","rpashen1955@yahoo.com","pstevens@satx.rr.com","cheryb13@satx.rr.com","kressler@satx.rr.com","bcerne1@yahoo.com","ada@obht.com","tina.gomez@usdoj.gov","surgemaster786@gmail.com","bjtexas05@gmail.com","docseek@dsitsa.com","emmetts60@yahoo.com","keblomquist@gmail.com","lorigarcia621@yahoo.com","mich_ella@yahoo.com","rljones64@yahoo.com"]
      }
    }
    

    
    puts "\n"
    setup_data.each_pair do |label, data|
      results = {
        :skipping => 0,
        :updating => 0,
        :creating => 0
      }
      publisher = Publisher.find_by_label(label)
      if publisher
        if publisher.signup_discount
          emails = data["emails"]
          puts "updating: #{publisher.name}"
          if emails.present?
            puts "  checking: #{emails.size} email addresses.\n"
            emails.each do |email|
              result  = create_or_update_publisher_consumer_by_email(publisher, email)
              results[result] += 1
            end
          else
            puts "  no emails to update"
          end          
        else
          puts "no signup discount for #{publisher.label}"
        end
      else
        puts "we were unable to find a publisher with a lable of '#{label}'"  
      end
      puts "    skipped[#{results[:skipping]}]"
      puts "    updated[#{results[:updating]}]"
      puts "    created[#{results[:creating]}]"
      puts "\n"
    end
    
    
  end
  
  def create_or_update_publisher_consumer_by_email(publisher, email)\
    result   = :skipping
    consumer = publisher.consumers.find_by_email(email)      
    unless consumer && consumer.signup_discount
      if consumer
        result = :updating
      else
        consumer = publisher.consumers.build(
            :name => "Your Name",
            :email => email,
            :password => '16KSn0T2kcw7SkFT',
            :password_confirmation => '16KSn0T2kcw7SkFT',
            :need_setup => true,
            :agree_to_terms => true
        )
        result = :creating
      end
      consumer.signup_discount = publisher.signup_discount
      unless consumer.save
        puts "              -- OOPS, couldn't save #{email} due to: #{consumer.errors.full_messages}"
      end
    end
    result
  end
end