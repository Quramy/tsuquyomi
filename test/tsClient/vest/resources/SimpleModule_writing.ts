module SimpleModule {
  export interface Runnable {
    run: ()=> any;
  }
  export class MyClass implements Runnable{
    name: string;
    greeting: string;
    constructor (options?: {name?: string; priority?: number}) {
    }
    say (): string {
      return this.greeting;
    }
    run () {
      this.say()
    }
  }

  var myObj = new MyClass();
  myObj.s
  export function main (): void {
    myObj.say();
    return;
  }
}
