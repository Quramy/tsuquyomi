module Test {

    var hoge = 1, foo = hoge;
    var x = hoge;

    /**
     *
     * @param bar An argument
     * 
     **/
    var someFunc = (bar: string) => { };

    var otherFunc = () => {
        var prefix;
        console.log(' prefix  ');
        console.log("   prefix ");
        console.log(`  prefix `);
    }

}
