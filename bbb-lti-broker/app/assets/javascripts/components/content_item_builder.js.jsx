var ContentItemBuilder = createReactClass({

  propTypes: {
    data: PropTypes.string,
    returnUrl: PropTypes.string,
    ltiVersion: PropTypes.string,
    ltiLaunchUrl: PropTypes.string,
    ltiUpdateUrl: PropTypes.string,
    textFileUrl: PropTypes.string,
    videoUrl: PropTypes.string,
    ccFileUrl: PropTypes.string,
    consumerKey: PropTypes.string,
    documentTargets: PropTypes.array,
    mediaTypes: PropTypes.array
  },

  getInitialState: function () {
    return {
      contentItems: {
        "@context": "http://purl.imsglobal.org/ctx/lti/v1/ContentItem",
        "@graph": []
      }
    };
  },

  updateContentItems: function () {
    this.setState({contentItems: this.refs.contentItemsElement.toJSON()});
  },

  render: function () {
    return (
      <div style={{'background': 'white'}} >
        <ContentItemBuilder.ContentItems
          ltiLaunchUrl={this.props.ltiLaunchUrl}
          ltiUpdateUrl={this.props.ltiUpdateUrl}
          textFileUrl={this.props.textFileUrl}
          videoUrl={this.props.videoUrl}
          ccFileUrl={this.props.ccFileUrl}
          documentTargets={this.props.documentTargets}
          mediaTypes={this.props.mediaTypes}
          updateContentItems={this.updateContentItems}
          ref="contentItemsElement"
          />
        <hr/>
        <ContentItemBuilder.ContentItemMessage
          data={this.props.data}
          returnUrl={this.props.returnUrl}
          ltiVersion={this.props.ltiVersion}
          contentItems={this.state.contentItems}
          consumerKey={this.props.consumerKey}
        />
      </div>
    );
  }
});