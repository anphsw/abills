<style type="text/css">
  .item {
    text-align: center;
    height: 300px !important;
  }

  .carousel {
    height: 300px;
    width: 100%;
  }

  .slide {
    background: rgb(168, 168, 167);
    margin-bottom: 8px;
    border-radius: 4px;
  }

  .carousel-control.left, .carousel-control.right {
    background-image: none;
    filter: none;
  }
</style>


<div id="myCarousel" class="carousel slide" data-interval="3000" data-ride="carousel">
  <ol class="carousel-indicators">
    %INDICATORS%
  </ol>
  <div class="carousel-inner">
    %CONTENT%
  </div>

  <a class="carousel-control left" style='float: left; margin-left: 15px;' href="#myCarousel" data-slide="prev">
    <span class="fa fa-chevron-left"></span>
  </a>
  <a class="carousel-control right" style='float: right; margin-right: 15px;' href="#myCarousel" data-slide="next">
    <span class="fa fa-chevron-right"></span>
  </a>
</div>