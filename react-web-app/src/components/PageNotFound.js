import React from "react";

class PageNotFound extends React.Component {

  render() {
    return (
      <div className="d-flex align-items-center justify-content-center vh-100">
        <div className="text-center">
            <p className="fs-3"> <span class="text-danger">Oops!</span> Page not found.</p>
            <p className="lead">The page you’re looking for doesn’t exist.</p>
        </div>
      </div>
    )
  }

}

export default PageNotFound;
