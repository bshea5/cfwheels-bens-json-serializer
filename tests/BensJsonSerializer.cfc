component extends="wheels.Test"  hint="Unit Tests" {
    /**
	 * Executes once before this package's first test case.
     * 
     * Create a bin for test to be performed. This will make it easier to 
     * clean up afterwards.
	 */
	function packageSetup() {
        // _testserializer_ = application.wheels.serializer;
	}

    /**
	 * Executes once after this package's last test case.
	 */
	function packageTeardown() {}
    
    /**
	 * Executes before every test case.
	 */
	function setup() {}
    
    /**
	 * Executes after every test case.
	 */
	function teardown() {}


	function Test_Serializer() {
        before = {
            "hello": "world",
            "foo": 1.0
        };
        after = benSerializeJSON(before);
        
        assert('truthy(after)');
        assert('after EQ "{""hello"":""world"",""foo"":""1.0""}"');
    }

    function Test_Init() {
        serializer = initBenSerializer()
            .asInteger("foo");

        before = {
            "hello": "world",
            "foo": 1.0
        };
        after = serializer.serialize(before);

        assert('truthy(after)');
        assert('after EQ "{""hello"":""world"",""foo"":1.0}"');
    }
}
