<style type='text/css'>

  .item {
    text-align: center;
    height: 300px !important;
  }

  .portal.carousel {
    width: 100%;
  }

  .portal.slide {
    background: rgb(168, 168, 167);
    margin-bottom: 8px;
    border-radius: 4px;
  }

  .portal .carousel-control.left, .portal .carousel-control.right {
    background-image: none;
    filter: none;
  }

  .important {
    background: #f78345;
  }

  .article-header {
    color:black;
    font-size: 16pt;
    text-align: center;
    margin-top: 50px;
  }

  .article-text {
    height: 60px;
    overflow: hidden;
    overflow-y: hidden;
    text-overflow: ellipsis;
    text-align: center;
  }
  .carousel-item.with-picture {
    background-size: cover;
    filter: brightness(80%);
  }

  .carousel-item.with-picture:hover {
    filter: none;
  }
</style>


<div id='myPortalCarousel' class='carousel portal slide' data-interval='3000' data-ride='carousel'>
  <ol class='carousel-indicators'>
    %INDICATORS%
  </ol>
  <div class='carousel-inner'>
    %CONTENT%
  </div>

  <a class='carousel-control-prev' href='#myPortalCarousel' data-slide='prev'>
    <span class='carousel-control-prev-icon' aria-hidden='true'></span>
    <span class='sr-only'>Previous</span>
  </a>
  <a class='carousel-control-next' href='#myPortalCarousel' data-slide='next'>
    <span class='carousel-control-next-icon' aria-hidden='true'></span>
    <span class='sr-only'>Next</span>
  </a>
</div>