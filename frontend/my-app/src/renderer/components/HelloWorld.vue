<template>
  <v-container>
    <v-layout
            align-center
            wrap
    >
      <v-flex xs12>
        <v-img
                :src="require('../assets/logo.svg')"
                class="my-3"
                contain
                height="200"
        ></v-img>
      </v-flex>

      <v-flex mb-4 align-center>
        <h1 class="display-1 font-weight-bold mb-3 text-xs-center">
          Load Your Certificate
        </h1>
        <div class="container">

          <form enctype="multipart/form-data" novalidate v-if="isInitial || isSaving">
            <div class="dropbox">
              <input type="file" :name="uploadFieldName" :disabled="isSaving" @change="filesChange($event.target.name, $event.target.files)"
                     class="input-file">
              <p v-if="isInitial">
                Drag your file here to begin<br> or click to browse
              </p>
              <p v-if="isSaving">
                Loading file...
              </p>
            </div>
          </form>

          <div v-if="isSuccess" align="center" justify="center">
            <h2>Upload certificate successfully.</h2>
            <p>
              <a href="javascript:void(0)" @click="reset()">Upload again</a>
            </p>
          </div>

          <div v-if="isFailed" align="center" justify="center">
            <h2>Loading failed.</h2>
            <p>
              <a href="javascript:void(0)" @click="reset()">Try again</a>
            </p>
            <pre>{{ uploadError }}</pre>
          </div>

        </div>
      </v-flex>
    </v-layout>
  </v-container>
</template>

<script>
  import JsZip from 'jszip'
  import {loadCerts} from '../lib/LoadCerts'

  const STATUS_INITIAL = 0, STATUS_SAVING = 1, STATUS_SUCCESS = 2, STATUS_FAILED = 3

  export default {
    name: 'app',
    data () {
      return {
        uploadedFiles: [],
        uploadError: null,
        currentStatus: null,
        uploadFieldName: ''
      }
    },
    computed: {
      isInitial () {
        return this.currentStatus === STATUS_INITIAL
      },
      isSaving () {
        return this.currentStatus === STATUS_SAVING
      },
      isSuccess () {
        return this.currentStatus === STATUS_SUCCESS
      },
      isFailed () {
        return this.currentStatus === STATUS_FAILED
      }
    },
    methods: {
      reset () {
        this.currentStatus = STATUS_INITIAL
        this.uploadedFiles = []
        this.uploadError = null
      },
      filesChange (fieldName, fileList) {
        this.currentStatus = STATUS_SAVING

        if (!fileList.length) {
          this.currentStatus = STATUS_FAILED
          return
        }

        Array
          .from(Array(fileList.length).keys())
          .map(x => {
            console.log(fileList[x])
            this.unzipFile(fileList[x])
          })

        this.currentStatus = STATUS_SUCCESS
      },
      async unzipFile (f) {
        console.log('Unzipping...')

        let zip = null
        try {
          zip = await JsZip.loadAsync(f)
        } catch (e) {
          console.error('Error reading ' + f.name + ': ' + e.message)
          this.currentStatus = STATUS_FAILED
          this.uploadError = 'Not a zip file!'
          throw Error('Not a zip file!')
        }

        const ret = await loadCerts(zip)
        if (ret !== true) {
          this.currentStatus = STATUS_FAILED
          this.uploadError = ret
          throw Error(ret)
        } else {
          this.currentStatus = STATUS_SUCCESS
        }
      }
    },
    mounted () {
      this.reset()
    }
  }
</script>

<style>
  .dropbox {
    outline: 2px dashed grey;
    /* the dash box */
    outline-offset: -10px;
    background: lightcyan;
    color: dimgray;
    padding: 10px 10px;
    height: 80px;
    position: relative;
    cursor: pointer;
    width: 50%;
    margin: auto;
  }
  .input-file {
    opacity: 0;
    height: 80px;
    position: absolute;
    cursor: pointer;
    width: 100%;
  }
  .dropbox:hover {
    background: lightblue;
  }
  .dropbox p {
    font-size: 1.2em;
    text-align: center;
    padding: 5px 0;
  }
  .center {
    align: center;
    justify: center;
  }
</style>
