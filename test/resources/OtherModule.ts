/// <reference path="SimpleModule.ts" />

module SimpleModule {
  export class Hoge implements Runnable {
    run () {
      console.log('hoge')
    }
  }
}
