class FileMailer < ActionMailer::Base
  def file(email, subj, file_path, content_type = "text/csv")
    recipients    email
    from          "Analog Analytics <support@analoganalytics.com>"
    subject       subj
    content_type  "multipart/mixed"

    attachment :filename      => File.basename(file_path), 
               :content_type  => content_type, 
               :body          => File.read(file_path)
  end
end
