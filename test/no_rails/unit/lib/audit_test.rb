require File.dirname(__FILE__) + "/./lib_helper"

class AuditTest < Test::Unit::TestCase

	context "audited" do

		setup do
			class AuditedClass; end
			AuditedClass.send( :include, Audit )
			AuditedClass.expects( :before_save ).with( :set_updated_by )
			AuditedClass.expects( :after_create ).with( :create_initial_version_if_necessary )
		end			

		context "with no options" do
			
			should "call versioned with nil" do
				AuditedClass.expects( :versioned )
				AuditedClass.class_eval do
					audited 
				end
			end

		end

		context "with only option" do

			should "call versioned with supplied options" do
				AuditedClass.expects( :versioned ).with( :only => [:name] )
				AuditedClass.class_eval do
					audited :only => [:name]
				end
			end

		end

		context "with except option" do

			should "call versioned with supplied options" do
				AuditedClass.expects( :versioned ).with( :except => [:name] )
				AuditedClass.class_eval do
					audited :except => [:name]
				end
			end

		end

		context "with initial_version option" do

			should "call versioned with supplied options" do
				AuditedClass.expects( :versioned )
				AuditedClass.expects( :prepare_versioned_options ).with( :initial_version => true )
				AuditedClass.class_eval do
					audited :initial_version => true
				end
			end

		end

	end

	context "audited_translations" do

		setup do
			class AuditedTranslationClass; end
			class AuditedClass; end
			AuditedClass.send( :include, Audit )
		end

		context "with one attribute, of :name" do

			should "call translates with :name" do				
				AuditedClass.expects( :translates ).with( :name )
				AuditedClass.expects( :translation_class ).returns( AuditedTranslationClass )
				AuditedTranslationClass.expects( :class_eval )
				AuditedClass.class_eval do
					audited_translations :name
				end
			end

		end

		context "with multiple attributes, of :name, :tagline" do

			should "call translates with :name, :tagline" do				
				AuditedClass.expects( :translates ).with( :name, :tagline )
				AuditedClass.expects( :translation_class ).returns( AuditedTranslationClass )
				AuditedTranslationClass.expects( :class_eval )
				AuditedClass.class_eval do
					audited_translations :name, :tagline
				end
			end

		end

	end

end