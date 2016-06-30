define(["../../../public/javascripts/translations.js"], function() {

	return {
		runTests: function() {
      module("I18n");

      test("default values", function() {
        ok(I18n.translations, "should not have empty translations");
        equal(I18n.locale, 'en');
      });

      module("I18n translation", {
        setup: function() {
          I18n.locale = 'en';
          I18n.translations = {
            'en': { 'test': 'Test', 'foo': 'Foo' },
            'es': { 'test': 'Testo' }
          };
        }
      });

      test("should return keys translation based on locale", function() {
        equal(I18n.t('test'), 'Test');
        I18n.locale = 'es';
        equal(I18n.t('test'), 'Testo');
      });

      test("should return default translations if missing key or locale", function() {
        // missing key
        I18n.locale = 'es';
        equal(I18n.t('foo'), 'Foo');
        // missing locale object
        I18n.locale = 'el';
        equal(I18n.t('foo'), 'Foo');
      });
	  }
  }
		
});
