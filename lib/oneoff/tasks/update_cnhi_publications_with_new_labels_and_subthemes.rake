namespace :oneoff do
  
  desc "update cnhi publications with new labels and subthemes"
  task :update_cnhi_publications_with_new_labels_and_subthemes => :environment do
    publications = {
      'cnhi-stanleynewspress' => { :label => 'cnhi-thesnaponline', :sub_theme => 'reddevil' },
      'cnhi-americustimesrecorder' => { :label => 'cnhi-americustimesrecorder', :sub_theme => 'bluesun' },
      'cnhi-theheraldbulletin' => { :label => 'cnhi-heraldbulletin', :sub_theme => 'bluesun' },
      'cnhi-andovertownsman' => { :label => 'cnhi-andovertownsman', :sub_theme => 'bluesun' },
      'cnhi-therandolphguide' => { :label => 'cnhi-randolphguide', :sub_theme => 'funkycool' },
      'cnhi-theindependent' => { :label => 'cnhi-dailyindependent', :sub_theme => 'willytimes' },
      'cnhi-thestarbeacon' => { :label => 'cnhi-starbeacon', :sub_theme => 'bluesun' },
      'cnhi-thenewscourier' => { :label => 'cnhi-enewscourier', :sub_theme => 'willytimes' },
      'cnhi-athensdailyreview' => { :label => 'cnhi-athensreview', :sub_theme => 'reddevil' },
      'cnhi-hendrickscountryflyer' => { :label => 'cnhi-hendricks', :sub_theme => 'bluesun' },
      'cnhi-batesvilleheraldtribune' => { :label => 'cnhi-batesville', :sub_theme => 'bluesun' },
      'cnhi-theregisterherald' => { :label => 'cnhi-registerherald', :sub_theme => 'willytimes' },
      'cnhi-bluefielddailytelegraph' => { :label => 'cnhi-bdtonline', :sub_theme => 'willytimes' },
      'cnhi-dailyiowegian' => { :label => 'cnhi-dailyiowegian', :sub_theme => 'reddevil' },
      'cnhi-chickashaexpressstar' => { :label => 'cnhi-chickashanews', :sub_theme => 'willytimes' },
      'cnhi-claremoredailyprogress' => { :label => 'cnhi-claremoreprogress', :sub_theme => 'bluesun' },
      'cnhi-cleburnetimesreview' => { :label => 'cnhi-cleburnetimesreview', :sub_theme => 'reddevil' },
      'cnhi-clintonherald' => { :label => 'cnhi-clintonherald', :sub_theme => 'willytimes' },
      'cnhi-commercejournal' => { :label => 'cnhi-commercejournal', :sub_theme => 'funkycool' },
      'cnhi-cooperstowncrier' => { :label => 'cnhi-cooperstowncrier', :sub_theme => 'reddevil' },
      'cnhi-timestribune' => { :label => 'cnhi-thetimestribune', :sub_theme => 'bluesun' },
      'cnhi-cordeledispatch' => { :label => 'cnhi-cordeledispatch', :sub_theme => 'bluesun' },
      'cnhi-corsicanadailysun' => { :label => 'cnhi-corsicanadailysun', :sub_theme => 'bluesun' },
      'cnhi-crossvillechronicle' => { :label => 'cnhi-crossvillechronicle', :sub_theme => 'bluesun' },
      'cnhi-thecullmantimes' => { :label => 'cnhi-cullmantimes', :sub_theme => 'willytimes' },
      'cnhi-cumberlandtimesnews' => { :label => 'cnhi-timesnews', :sub_theme => 'willytimes' },
      'cnhi-thedailycitizen' => { :label => 'cnhi-daltondailycitizen', :sub_theme => 'bluesun' },
      'cnhi-commercialnews' => { :label => 'cnhi-commercialnews', :sub_theme => 'reddevil' },
      'cnhi-derrynewsweekender' => { :label => 'cnhi-derrynews', :sub_theme => 'funkycool' },
      'cnhi-theduncanbanner' => { :label => 'cnhi-duncanbanner', :sub_theme => 'reddevil' },
      'cnhi-edmondsun' => { :label => 'cnhi-edmondsun', :sub_theme => 'okieearth' },
      'cnhi-effinghamdailynews' => { :label => 'cnhi-effinghamdailynews', :sub_theme => 'willytimes' },
      'cnhi-enidnewseagle' => { :label => 'cnhi-enidnews', :sub_theme => 'willytimes' },
      'cnhi-timeswestvirginian' => { :label => 'cnhi-timeswv', :sub_theme => 'bluesun' },
      'cnhi-northjeffersonnews' => { :label => 'cnhi-njeffersonnews', :sub_theme => 'willytimes' },
      'cnhi-glasgowdailytimes' => { :label => 'cnhi-glasgowdailytimes', :sub_theme => 'bluesun' },
      'chni-goshennews' => { :label => 'cnhi-goshennews', :sub_theme => 'none' },
      'cnhi-graysonjournalenquirer' => { :label => 'cnhi-journaltimes', :sub_theme => 'reddevil' },
      'cnhi-greensburgdailynews' => { :label => 'cnhi-greensburg', :sub_theme => 'earthy' },
      'cnhi-greenvilleheraldbanner' => { :label => 'cnhi-heraldbanner', :sub_theme => 'willytimes' },
      'cnhi-alliednews' => { :label => 'cnhi-alliednews', :sub_theme => 'funkycool' },
      'cnhi-cedarcreekpilot' => { :label => 'cnhi-cedarcreekpilot', :sub_theme => 'reddevil' },
      'cnhi-thehuntsvilleitem' => { :label => 'cnhi-itemonline', :sub_theme => 'bluesun' },
      'cnhi-jacksonvilledailyprogress' => { :label => 'cnhi-jacksonvilleprogress', :sub_theme => 'willytimes' },
      'cnhi-theeveningnews' => { :label => 'cnhi-newstribune', :sub_theme => 'willytimes' },
      'cnhi-thetribunedemocrat' => { :label => 'cnhi-tribunedemocrat', :sub_theme => 'willytimes' },
      'cnhi-knoxvillejournalexpress' => { :label => 'cnhi-journalexpress', :sub_theme => 'willytimes' },
      'cnhi-kokomotribune' => { :label => 'cnhi-kokomotribune', :sub_theme => 'okieearth' },
      'cnhi-thestarherald' => { :label => 'cnhi-starherald', :sub_theme => 'willytimes' },
      'cnhi-laurelleadercall' => { :label => 'cnhi-leadercall', :sub_theme => 'bluesun' },
      'cnhi-thelebanonreporter' => { :label => 'cnhi-reporter', :sub_theme => 'willytimes' },
      'cnhi-theleedsnews' => { :label => 'cnhi-theleedsnews', :sub_theme => 'earthy' },
      'cnhi-suwanneedemocrat' => { :label => 'cnhi-suwanneedemocrat', :sub_theme => 'earthy' },
      'cnhi-lockportunionsunjournal' => { :label => 'cnhi-lockportjournal', :sub_theme => 'willytimes' },
      'cnhi-thepharostribune' => { :label => 'cnhi-logansport', :sub_theme => 'okieearth' },
      'cnhi-thesentinelecho' => { :label => 'cnhi-sentinelecho', :sub_theme => 'willytimes' },
      'cnhi-mankatofreepress' => { :label => 'cnhi-mankatofreepress', :sub_theme => 'willytimes' },
      'cnhi-mcalesternewscapital' => { :label => 'cnhi-mcalesternews', :sub_theme => 'earthy' },
      'cnhi-timesleader' => { :label => 'cnhi-timesleader', :sub_theme => 'willytimes' },
      'cnhi-themeadvilletribune' => { :label => 'cnhi-meadvilletribune', :sub_theme => 'bluesun' },
      'cnhi-thejournalregister' => { :label => 'cnhi-journalregister', :sub_theme => 'funkycool' },
      'cnhi-themeridianstar' => { :label => 'cnhi-meridianstar', :sub_theme => 'reddevil' },
      'cnhi-theunionrecorder' => { :label => 'cnhi-unionrecorder', :sub_theme => 'bluesun' },
      'cnhi-mineralwellsindex' => { :label => 'cnhi-mineralwellsindex', :sub_theme => 'funkycool' },
      'cnhi-montgomeryherald' => { :label => 'cnhi-montgomeryherald', :sub_theme => 'willytimes' },
      'cnhi-themoultrieobserver' => { :label => 'cnhi-moultrieobserver', :sub_theme => 'bluesun' },
      'cnhi-mtvernonregisternews' => { :label => 'cnhi-registernews', :sub_theme => 'willytimes' },
      'cnhi-themuskogeephoenix' => { :label => 'cnhi-muskogee', :sub_theme => 'okieearth' },
      'cnhi-niagaragazette' => { :label => 'cnhi-niagaragazette', :sub_theme => 'willytimes' },
      'cnhi-thenormantranscript' => { :label => 'cnhi-thenormantranscript', :sub_theme => 'bluesun' },
      'cnhi-thefayettetribune' => { :label => 'cnhi-fayettetribune', :sub_theme => 'earthy' },
      'cnhi-thedailystar' => { :label => 'cnhi-thedailystar', :sub_theme => 'bluesun' },
      'cnhi-theorangeleader' => { :label => 'cnhi-orangeleader', :sub_theme => 'funkycool' },
      'cnhi-ottumwadailycourier' => { :label => 'cnhi-ottumwadailycourier', :sub_theme => 'willytimes' },
      'cnhi-palestineheraldpress' => { :label => 'cnhi-palestineherald', :sub_theme => 'earthy' },
      'cnhi-farmtalk' => { :label => 'cnhi-farmtalk', :sub_theme => 'funkycool' },
      'cnhi-stclairnewsaegis' => { :label => 'cnhi-stclairnewsaegis', :sub_theme => 'willytimes' },
      'chni-pellachronicle' => { :label => 'cnhi-pellachronicle', :sub_theme => 'willytimes' },
      'cnhi-picayuneitem' => { :label => 'cnhi-picayuneitem', :sub_theme => 'willytimes' },
      'cnhi-theportarthurnews' => { :label => 'cnhi-panews', :sub_theme => 'bluesun' },
      'cnhi-roysecityheraldbanner' => { :label => 'cnhi-roysecityheraldbanner', :sub_theme => 'willytimes' },
      'cnhi-rushvillerepublican' => { :label => 'cnhi-rushville', :sub_theme => 'reddevil' },
      'cnhi-sanmarcosdailyrecord' => { :label => 'cnhi-sanmarcosrecord', :sub_theme => 'bluesun' },
      'cnhi-theherald' => { :label => 'cnhi-sharonherald', :sub_theme => 'bluesun' },
      'cnhi-shelbyvilledailyunion' => { :label => 'cnhi-shelbyville', :sub_theme => 'willytimes' },
      'cnhi-thestillwaternewspress' => { :label => 'cnhi-stwnewspress', :sub_theme => 'funkycool' },
      'cnhi-thedailyitem' => { :label => 'cnhi-dailyitem', :sub_theme => 'lakeshore' },
      'cnhi-thedailysoutherner' => { :label => 'cnhi-dailysoutherner', :sub_theme => 'willytimes' },
      'cnhi-thetribunestar' => { :label => 'cnhi-tribstar', :sub_theme => 'willytimes' },
      'cnhi-thomasvilletimesenterprise' => { :label => 'cnhi-timesenterprise', :sub_theme => 'bluesun' },
      'cnhi-thetiftongazette' => { :label => 'cnhi-tiftongazette', :sub_theme => 'bluesun' },
      'cnhi-valdostadailytimes' => { :label => 'cnhi-valdostadailytimes', :sub_theme => 'na_black' },
      'cnhi-thewashingtontimesherald' => { :label => 'cnhi-washtimesherald', :sub_theme => 'bluesun' },
      'cnhi-weatherforddemocrat' => { :label => 'cnhi-weatherforddemocrat', :sub_theme => 'bluesun' },
      'cnhi-woodwardnews' => { :label => 'cnhi-woodwardnews', :sub_theme => 'okieearth' },
      'cnhi-therecordeagle' => { :label => 'cnhi-recordeagle', :sub_theme => 'none' }
    }
    
    puts "updating #{publications.size} publications out of #{PublishingGroup.find_by_label("cnhi").publishers.size}"
    publications.each_pair do |label, values|
      publisher = Publisher.find_by_label(label)            
      if publisher
        publisher.label = values[:label]
        publisher.sub_theme = values[:sub_theme]
        publisher.save
      else
        puts "unable to find publisher with label: #{label}" unless publisher
      end
    end
    
    
  end
  
end