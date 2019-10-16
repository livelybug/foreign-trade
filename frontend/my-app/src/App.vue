<template>
  <v-app>
    <v-app-bar app>
      <v-toolbar-title class="headline text-uppercase">
        <span>foreign trade</span>
        <span class="font-weight-light"> decentralizing</span>
      </v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn
        text
        target="_blank"
      >
        <span class="mr-2">Hyperledger Fabric</span>
      </v-btn>
    </v-app-bar>

    <v-content>
      <HelloWorld/>
    </v-content>
  </v-app>
</template>

<script>
import HelloWorld from './components/HelloWorld';
// import Full from "./components/Full";

export default {
  name: 'App',
  components: {
    HelloWorld,
  },
  data: () => ({
    //
  }),
};
</script>
