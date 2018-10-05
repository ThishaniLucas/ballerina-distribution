import ballerina/test;
import ballerina/io;

any[] outputs = [];
int counter = 0;

// This is the mock function which will replace the real function.
@test:Mock {
    packageName: "ballerina/io",
    functionName: "println"
}
public function mockPrint(any... s) {
    outputs[counter] = s[0];
    counter += 1;
}

@test:Config
function testFunc() {
    // Invoking the main function.
    main();
    test:assertEquals(outputs[0], "Answer: 48");
    test:assertEquals(outputs[1], "Answer: 63");
    test:assertEquals(outputs[2], "Answer: 15");
}