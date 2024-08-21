import React from "react";

const LudoTiles: React.FC = () => {
  return (
    <React.Fragment>
      <div className="container-row1 clearfix">
        <div className="row1-col1">
          <div className="row1-col1-child clearfix ">
            <div className="green" />
            <div className="green" />
            <div className="green" />
            <div className="green" />
          </div>
        </div>
        <div className="row1-col2 clearfix">
          <div />
          <div />
          <div />
          <div />
          <div className="yellow" />
          <div className="yellow" />
          <div></div>
          <div className="yellow" />
          <div />
          <div />
          <div className="yellow" />
          <div />
          <div />
          <div className="yellow" />
          <div />
          <div />
          <div className="yellow" />
          <div />
        </div>
        <div className="row1-col3">
          <div className="row1-col3-child clearfix">
            <div className="yellow" />
            <div className="yellow" />
            <div className="yellow" />
            <div className="yellow" />
          </div>
        </div>
      </div>

      <div className="container-row2 clearfix">
        <div className="row2-col1 clearfix">
          <div />
          <div className="green" />
          <div />
          <div />
          <div />
          <div />
          <div />
          <div className="green" />
          <div className="green" />
          <div className="green" />
          <div className="green" />
          <div className="green" />
          <div />
          <div />
          <div></div>
          <div />
          <div />
          <div />
        </div>
        <div className="row2-col2">
          <div className="contain-triangles">
            <div className="white" />
            <div className="white" />
            <div className="white" />
            <div className="white" />
          </div>
        </div>
        <div className="row2-col3 clearfix">
          <div />
          <div />
          <div />
          <div></div>
          <div />
          <div />
          <div className="blue" />
          <div className="blue" />
          <div className="blue" />
          <div className="blue" />
          <div className="blue" />
          <div />
          <div />
          <div />
          <div />
          <div />
          <div className="blue" />
          <div />
        </div>
      </div>

      <div className="container-row3 clearfix">
        <div className="row3-col1">
          <div className="row3-col1-child clearfix">
            <div className="red" />
            <div className="red" />
            <div className="red" />
            <div className="red" />
          </div>
        </div>
        <div className="row3-col2 clearfix">
          <div />
          <div className="red" />
          <div />
          <div />
          <div className="red" />
          <div />
          <div />
          <div className="red" />
          <div />
          <div />
          <div className="red" />
          <div></div>
          <div className="red" />
          <div className="red" />
          <div />
          <div />
          <div />
          <div />
        </div>
        <div className="row3-col3">
          <div className="row3-col3-child clearfix">
            <div className="blue" />
            <div className="blue" />
            <div className="blue" />
            <div className="blue" />
          </div>
        </div>
      </div>
    </React.Fragment>
  );
};

export default LudoTiles;
