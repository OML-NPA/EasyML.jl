
## Package features

A training loop with 
 - a GUI window
 - GPU support
 - support for changing in real time
    - number of epochs
    - learning rate
    - number of tests

Classification, regression and segmentation on any data with [Flux.jl](https://github.com/FluxML/Flux.jl) models are supported.

```@raw html
<style>

.column1 {
  float: left;
  width: 40.6%;
  padding: 0.25%;
}

.column2 {
  float: left;
  width: 59.4%;
  padding: 0.25%;
}

.filler {
  float: left;
  width: 100%;
  margin-bottom: 0.6em;
}

row::after{
   content: "";
  clear: both;
  display: table;
}

</style>
<div class="row">
  <div class="column1">
    <img   src="./assets/images/train.png">
  </div>
  <div class="column2">
    <img   src="./assets/images/training_options3.png">
  </div>
</div>
<div class="filler">
</div>

```

### Installation

Run `] add https://github.com/OML-NPA/EasyMLTraining.jl` in REPL.