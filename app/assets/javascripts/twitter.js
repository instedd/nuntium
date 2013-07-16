function twitter_view_rate_limit_status(id) {
  $.ajax({
    type: "GET",
    url: '/twitter/view_rate_limit_status',
    data: {id: id},
    success: function(data) {
      alert(data)
    },
    error: function() {
      alert('An error happened while retreiving the twitter rate limit status :-(');
    }
  });
}
