// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'expand_icon.dart';
import 'mergeable_material.dart';
import 'theme.dart';

const double _kPanelHeaderCollapsedHeight = 48.0;
const double _kPanelHeaderExpandedHeight = 64.0;

/// Signature for the callback that's called when an [ExpansionPanel] is
/// expanded or collapsed.
///
/// The position of the panel within an [ExpansionPanelList] is given by
/// [panelIndex].
typedef void ExpansionPanelCallback(int panelIndex, bool isExpanded);

/// Signature for the callback that's called when the header of the
/// [ExpansionPanel] needs to rebuild.
typedef Widget ExpansionPanelHeaderBuilder(BuildContext context, bool isExpanded);

/// A Material expansion panel. It has a header and a body and can be either
/// expanded or collapsed. The body of the panel is only visible when it is
/// expanded.
///
/// Expansion panels are only intended to be used as children for
/// [ExpansionPanelList].
///
/// See also:
///
///  * [ExpansionPanelList]
///  * <https://material.google.com/components/expansion-panels.html>
class ExpansionPanel {
  /// Creates an expansion panel to be used as a child for [ExpansionPanelList].
  ///
  /// None of the arguments can be null.
  ExpansionPanel({
    @required this.headerBuilder,
    @required this.body,
    this.isExpanded: false
  }) {
    assert(this.headerBuilder != null);
    assert(this.body != null);
    assert(this.isExpanded != null);
  }

  /// The widget builder that builds the expansion panels' header.
  final ExpansionPanelHeaderBuilder headerBuilder;

  /// The body of the expansion panel that's displayed below the header.
  ///
  /// This widget is visible only when the panel is expanded.
  final Widget body;

  /// Whether the panel is expanded.
  ///
  /// Defaults to false.
  final bool isExpanded;
}

/// A Material expansion panel list that lays out its children and animates
/// expansions.
///
/// See also:
///
///  * [ExpansionPanel]
///  * <https://material.google.com/components/expansion-panels.html>
class ExpansionPanelList extends StatelessWidget {
  /// Creates an expansion panel list widget. The [expansionCallback] is
  /// triggered when an expansion panel expand/collapse button is pushed.
  ExpansionPanelList({
    Key key,
    this.children: const <ExpansionPanel>[],
    this.expansionCallback,
    this.animationDuration: kThemeAnimationDuration
  }) : super(key: key) {
    assert(this.children != null);
    assert(this.animationDuration != null);
  }

  /// The children of the expansion panel list. They are layed in a similar
  /// fashion to [BlockBody].
  final List<ExpansionPanel> children;

  /// The callback that gets called whenever one of the expand/collapse buttons
  /// is pressed. The arguments passed to the callback are the index of the
  /// to-be-expanded panel in the list and whether the panel is currently
  /// expanded or not.
  ///
  /// This callback is useful in order to keep track of the expanded/collapsed
  /// panels in a parent widget that may need to react to these changes.
  final ExpansionPanelCallback expansionCallback;

  /// The duration of the expansion animation.
  final Duration animationDuration;

  bool _isChildExpanded(int index) {
    return children[index].isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final List<MergeableMaterialItem> items = <MergeableMaterialItem>[];
    const EdgeInsets kExpandedEdgeInsets = const EdgeInsets.symmetric(
      vertical: _kPanelHeaderExpandedHeight - _kPanelHeaderCollapsedHeight
    );

    for (int i = 0; i < children.length; i += 1) {
      if (_isChildExpanded(i) && i != 0 && !_isChildExpanded(i - 1))
        items.add(new MaterialGap(key: new ValueKey<int>(i * 2 - 1)));

      Row header = new Row(
        children: <Widget>[
          new Flexible(
            child: new AnimatedContainer(
              duration: animationDuration,
              curve: Curves.fastOutSlowIn,
              margin: _isChildExpanded(i) ? kExpandedEdgeInsets : EdgeInsets.zero,
              child: new SizedBox(
                height: _kPanelHeaderCollapsedHeight,
                child: children[i].headerBuilder(
                  context,
                  children[i].isExpanded
                )
              )
            )
          ),
          new Container(
            margin: const EdgeInsets.only(right: 8.0),
            child: new ExpandIcon(
              isExpanded: _isChildExpanded(i),
              padding: const EdgeInsets.all(16.0),
              onPressed: (bool isExpanded) {
                if (expansionCallback != null) {
                  expansionCallback(i, isExpanded);
                }
              }
            )
          )
        ]
      );

      items.add(
        new MaterialSlice(
          key: new ValueKey<int>(i * 2),
          child: new Column(
            children: <Widget>[
              header,
              new _AnimatedCrossFade(
                firstChild: new Container(height: 0.0),
                secondChild: children[i].body,
                crossFadeState: _isChildExpanded(i) ? _CrossFadeState.showSecond : _CrossFadeState.showFirst,
                duration: animationDuration,
                curve: Curves.fastOutSlowIn
              )
            ]
          )
        )
      );

      if (_isChildExpanded(i) && i != children.length - 1)
        items.add(new MaterialGap(key: new ValueKey<int>(i * 2 + 1)));
    }

    return new MergeableMaterial(
      hasDividers: true,
      children: items
    );
  }
}

// The child that is shown will fade in, and while the other will fade out.
enum _CrossFadeState {
  showFirst,
  showSecond
}

// A widget that cross-fades between two children and animates its bottom while
// clipping the children.
class _AnimatedCrossFade extends StatefulWidget {
  _AnimatedCrossFade({
    Key key,
    this.firstChild,
    this.secondChild,
    this.crossFadeState,
    this.duration,
    this.curve
  }) : super(key: key);

  final Widget firstChild;
  final Widget secondChild;
  final _CrossFadeState crossFadeState;
  final Duration duration;
  final Curve curve;

  @override
  _AnimatedCrossFadeState createState() => new _AnimatedCrossFadeState();
}

class _AnimatedCrossFadeState extends State<_AnimatedCrossFade> {
  AnimationController _controller;
  Animation<double> _firstAnimation;
  Animation<double> _secondAnimation;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(duration: config.duration);
    _firstAnimation = new Tween<double>(
      begin: 1.0,
      end: 0.0
    ).animate(
      new CurvedAnimation(
        parent: _controller,
        curve: new Interval(0.0, 0.6, curve: config.curve)
      )
    );
    _secondAnimation = new CurvedAnimation(
      parent: _controller,
      curve: new Interval(0.4, 1.0, curve: config.curve.flipped)
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateConfig(_AnimatedCrossFade oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (config.crossFadeState != oldConfig.crossFadeState) {
      switch (config.crossFadeState) {
        case _CrossFadeState.showFirst:
          _controller.reverse();
          break;
        case _CrossFadeState.showSecond:
          _controller.forward();
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Stack stack;

    if (_controller.status == AnimationStatus.completed ||
        _controller.status == AnimationStatus.forward) {
      stack = new Stack(
        overflow: Overflow.visible,
        children: <Widget>[
          new FadeTransition(
            opacity: _secondAnimation,
            child: config.secondChild
          ),
          new Positioned(
            left: 0.0,
            top: 0.0,
            right: 0.0,
            child: new FadeTransition(
              opacity: _firstAnimation,
              child: config.firstChild
            )
          )
        ]
      );
    } else {
      stack = new Stack(
        overflow: Overflow.visible,
        children: <Widget>[
          new FadeTransition(
            opacity: _firstAnimation,
            child: config.firstChild
          ),
          new Positioned(
            left: 0.0,
            top: 0.0,
            right: 0.0,
            child: new FadeTransition(
              opacity: _secondAnimation,
              child: config.secondChild
            )
          )
        ]
      );
    }

    return new ClipRect(
      child: new AnimatedSize(
        key: new ValueKey<Key>(config.key),
        alignment: FractionalOffset.topCenter,
        duration: config.duration,
        curve: config.curve,
        child: stack
      )
    );
  }
}
