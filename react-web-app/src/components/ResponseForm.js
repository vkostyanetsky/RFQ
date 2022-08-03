import React from "react";
import { useParams } from "react-router-dom";
import pic from "./images/circular_progress_indicator_square_large.gif"
import axios from "axios"
import SweetAlert from "react-bootstrap-sweetalert"

export function withRouter(Children){
  return(props)=>{

     const match  = {params: useParams()};
     return <Children {...props}  match = {match}/>
 }
}

class ResponseForm extends React.Component {

  constructor(props) {
    super(props)

    this.state = {
      isLoaded: false,      
      error: null,
      items: [],
      alert: ""
    }
    
    this.handleInventoryChange = this.handleInventoryChange.bind(this)
    this.handleQuestionsChange = this.handleQuestionsChange.bind(this)
    
    this.handleSaveAsDraft = this.handleSaveAsDraft.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this)

    this.showDraftSavedAlert = this.showDraftSavedAlert.bind(this)
  }

  showDraftSavedAlert() {
    const getAlert = () => (
      <SweetAlert 
        success 
        title="Success!" 
        onConfirm={() => this.hideAlert()}
      >
      The draft has been saved.
      </SweetAlert>
    )

    let itemsState = {...this.state.items}

    this.setState({
      items: itemsState,
      alert: getAlert()
    })
  }

  hideAlert() {
    let itemsState = {...this.state.items}
    
    this.setState({
      items: itemsState,
      alert: null
    })
  }

  handleSubmit(event) {
    event.preventDefault();    

    const request_url = `${process.env.REACT_APP_SERVER_URL}/Data/${this.props.match.params.id}/`
    const data = this.responseFormData(false)

    axios.post(request_url, data)
      .then(res => {
        this.setState({items: res.data})
      })
      .catch(function (error) {
          console.log(error);
      })
  }

  handleSaveAsDraft(event) {
    event.preventDefault();

    const request_url = `${process.env.REACT_APP_SERVER_URL}/Data/${this.props.match.params.id}/`
    console.log(`Sending a POST request to the REST service: ${request_url}`)

    let data = this.responseFormData(true)
    console.log(data)

    axios.post(request_url, data)
      .then(res => {
        this.setState({items: res.data})
        this.showDraftSavedAlert()
      })
      .catch(function (error) {
        console.log(error);
      });      
  }

  handleInventoryChange(event) {
    let itemsState = {
      ...this.state.items
    }
    let lineIndex = event.target.name.substring(1)
    let lineValue = event.target.value.replace(/[^0-9.]/g, '');
    lineValue = lineValue.replace(/^0+/, '');

    itemsState.Inventory[lineIndex].Price = lineValue

    this.setState({
      items: itemsState
    })
  }

  handleQuestionsChange(event) {    
    let itemsState = {
      ...this.state.items
    }
    let lineIndex = event.target.name.substring(1)

    itemsState.Questions[lineIndex].Answer = event.target.value

    this.setState({
      items: itemsState
    })
  }  

  responseFormData(saveAsDraft) {
    let inventory = {}

    for (let line of this.state.items.Inventory) {
      inventory[line.LineNumber] = line.Price
    }

    let questions = {}

    for (let line of this.state.items.Questions) {
      questions[line.LineNumber] = line.Answer
    }    

    return {
      "SaveAsDraft": saveAsDraft,
      "Inventory": inventory,
      "Questions": questions,
    }
  }


  componentDidMount() {
    const url_to_request = `${process.env.REACT_APP_SERVER_URL}/Data/${this.props.match.params.id}/`
    console.log(`Sending a GET request to the REST service: ${url_to_request}`)

    fetch(
      url_to_request
    )
      .then((res) => res.json())
      .then(
        (result) => {
          this.setState({
            isLoaded: true,
            items: result,
          });
        },
        (error) => {
          this.setState({
            isLoaded: true,
            error,
          });
        }
      );
  }

  renderError() {    
    return (
      <div className="d-flex align-items-center justify-content-center vh-100">
        <div className="text-center">
            <p className="fs-3"> <span class="text-danger">Oops!</span> Something went wrong.</p>
            <p className="lead">Try to refresh this page or feel free to contact us if the problem persists.</p>
        </div>
      </div>
    )      
  }

  renderLoading() {
    return (
      <div className="d-flex align-items-center justify-content-center vh-100">
        <div className="text-center">
            <img src={pic} alt="Loading..." />
        </div>
      </div>
    )
  }

  renderPosted() {
    return (
      <div className="d-flex align-items-center justify-content-center vh-100">
        <div className="text-center">
            <p className="fs-3">This response is submitted.</p>
            <p className="lead">Please contact us for further information.</p>
        </div>
      </div>
    )
  }

  renderResponseForQuotationIsNotFound() {
    return (
      <div className="d-flex align-items-center justify-content-center vh-100">
        <div className="text-center">
            <p className="fs-3">Response not found.</p>
            <p className="lead">Please contact us for further information.</p>
        </div>
      </div>
    )
  }  

  renderForm(items) {
    let inventory = items.Inventory.map(
      function(inventory, lineIndex) {
      let name = `i${lineIndex}`
        return (
          <tr key={inventory.LineNumber}>
            <th scope="row">{inventory.LineNumber}</th>
            <td>{inventory.Item}</td>
            <td>{inventory.UnitOfMeasure}</td>
            <td>{inventory.Quantity}</td>
            <td>
              <input className="form-control form-control-sm" name={name} value={inventory.Price} onChange={this.handleInventoryChange} />
            </td>
          </tr>
        )
      }, this
    )

    let questions = items.Questions.map(
      function(question, lineIndex) {
        let name = `q${lineIndex}`
        return (
          <tr key={question.LineNumber}>
            <th scope="row">{question.LineNumber}</th>
            <td>{question.Question}</td>
            <td>
              <input className="form-control form-control-sm" name={name} value={question.Answer} onChange={this.handleQuestionsChange} />
            </td>
          </tr>
        )
      }, this
    )

    return (
      <div className="container px-4">
        {this.state.alert}
        <h1>
          Response to RFQ <small className="text-muted">{items.Number}</small>
        </h1>

        <p className="h5">{items.Date}</p>
      
        <form>

        <h3>Inventory</h3>
        <table className="table">
          <thead>
            <tr>
              <th scope="col">#</th>
              <th scope="col">Description</th>
              <th scope="col">UOM</th>
              <th scope="col">Quantity</th>
              <th scope="col">Price</th>
            </tr>
          </thead>
          <tbody>
            {inventory}
          </tbody>
        </table>

        <h3>Questions</h3>
        <table className="table">
          <thead>
            <tr>
              <th scope="col">#</th>
              <th scope="col">Question</th>
              <th scope="col">Answer</th>
            </tr>
          </thead>
          <tbody>
            {questions}
          </tbody>
        </table>
      
        <div className="form-row text-center">
          <div className="col-12">
            <button className="btn btn-primary btn-lg" type="submit" onClick={this.handleSubmit}>Submit</button>
            &nbsp;
            <button className="btn btn-secondary btn-lg" type="button" onClick={this.handleSaveAsDraft}>Save as draft</button>        
          </div>
        </div>

        </form>

      </div>
    );
  }

  render() {    
    const { error, isLoaded, items } = this.state;
    
    if (error) {
      return this.renderError()
    }

    if (! isLoaded) {
      return this.renderLoading()
    }
      
    if (items.hasOwnProperty("ErrorCode")) {

      if (items.ErrorCode === 101) {
        return this.renderResponseForQuotationIsNotFound()
      }
      else {
        return this.renderError()
      }

    }

    if (! items.hasOwnProperty("Number")) {
      return this.renderError()
    }

    if (items.Posted) {
      return this.renderPosted()
    }

    return this.renderForm(items)
  }
}

export default withRouter(ResponseForm);
