#!/bin/bash -ev


# Copyright 2022 Google LLC

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
if [[ -z "$(pip list | grep deepspeed)" ]]; then
  pip install --upgrade pip
  pip install 'datasets>=2.9.0' evaluate transformers
  pip install nltk
  pip install rouge_score
  pip install ipywidgets
  pip install accelerate
  pip install scipy
  pip install sentencepiece
  pip install triton
  pip install deepspeed==0.12.3
  pip uninstall -y deepspeed
  DS_BUILD_EVOFORMER_ATTN=1 DS_BUILD_SPARSE_ATTN=1 DS_BUILD_RANDOM_LTD=1 DS_BUILD_QUANTIZER=1 DS_BUILD_CPU_ADAGRAD=1 DS_BUILD_FUSED_LION=1 DS_BUILD_CPU_LION=1 DS_BUILD_CCL_COMM=1 DS_BUILD_AIO=1 DS_BUILD_CPU_ADAM=1 DS_BUILD_FUSED_ADAM=1 DS_BUILD_FUSED_LAMB=1 DS_BUILD_TRANSFORMER=1 DS_BUILD_TRANSFORMER_INFERENCE=1 DS_BUILD_STOCHASTIC_TRANSFORMER=1 DS_BUILD_UTILS=1 pip install deepspeed==0.12.3 --global-option="build_ext"
fi

