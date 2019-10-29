<template>
  <v-app>
    <v-toolbar app>
      <v-toolbar-title class="headline text-uppercase">
        <span>foreign trade</span>
        <span class="font-weight-light"> decentralizing</span>
      </v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn
              depressed style="margin:0px;padding:0px 0px"
      >
        <span class="mr-0" align="right" justify="right">Hyperledger Fabric Powered</span>
      </v-btn>
    </v-toolbar>

    <v-content>
      <HelloWorld/>
    </v-content>
  </v-app>
</template>

<script>
  import HelloWorld from './components/HelloWorld'
// import Full from "./components/Full";

export default {
    name: 'App',
    components: {
      HelloWorld
    },
    data: () => ({
      //
    })
  }
</script>
