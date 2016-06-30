module PdfToTextHelper
  def extract_text_from_pdf(pdf, strip = true)
    receiver = PageTextReceiver.new(strip)
    PDF::Reader.string(pdf, receiver)
    receiver.content.inspect
  end
end
