module SimpleModule {
  export interface Runnable {
    run: ()=> any;
  }
  export class MyClass {
    name: string;
    greeting: string;
    constructor (options?: {name?: string; priority?: number}) {
    }
  }

  var myObj = new MyClass();

}
